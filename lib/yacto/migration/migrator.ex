defmodule Yacto.Migration.Migrator do
  require Logger

  @spec migrated_versions(Ecto.Repo.t(), atom, module) :: [integer]
  def migrated_versions(repo, app, schema) do
    verbose_schema_migration(repo, "retrieve migrated versions", fn ->
      Yacto.Migration.SchemaMigration.ensure_schema_migrations_table!(repo)
      Yacto.Migration.SchemaMigration.migrated_versions(repo, app, schema)
    end)
  end

  defp difference_migration(migrations, versions) do
    migrations
    |> Enum.filter(fn migration -> !Enum.member?(versions, migration.version) end)
  end

  @doc """
  Runs an up migration on the given repository.
  ## Options
    * `:log` - the level to use for logging of migration instructions.
      Defaults to `:info`. Can be any of `Logger.level/0` values or a boolean.
    * `:log_sql` - the level to use for logging of SQL instructions.
      Defaults to `false`. Can be any of `Logger.level/0` values or a boolean.
    * `:prefix` - the prefix to run the migrations on
    * `:dynamic_repo` - the name of the Repo supervisor process.
      See `c:Ecto.Repo.put_dynamic_repo/1`.
    * `:strict_version_order` - abort when applying a migration with old timestamp
  """
  def up(app, repo, schemas, migrations, opts \\ []) do
    sorted_migrations =
      case Yacto.Migration.Util.sort_migrations(migrations) do
        {:error, errors} ->
          for error <- errors do
            Logger.error(error)
          end

          raise inspect(errors)

        {:ok, sorted_migrations} ->
          sorted_migrations
      end

    for schema <- schemas do
      if Yacto.Migration.Util.allow_migrate?(schema, repo) do
        versions = migrated_versions(repo, app, schema)
        need_migrations = difference_migration(sorted_migrations, versions)

        for migration <- need_migrations do
          do_up(app, repo, schema, migration.module, opts)
        end
      end
    end

    :ok
  end

  defp do_up(app, repo, schema, migration, opts) do
    async_migrate_maybe_in_transaction(app, repo, schema, migration, :up, opts, fn ->
      attempt(repo, schema, migration, :forward, :up, :up, opts) ||
        attempt(repo, schema, migration, :forward, :change, :up, opts) ||
        {:error,
         Ecto.MigrationError.exception(
           "#{inspect(migration)} does not implement a `up/0` or `change/0` function"
         )}
    end)
  end

  defp async_migrate_maybe_in_transaction(app, repo, schema, migration, _direction, _opts, fun) do
    parent = self()
    ref = make_ref()
    dynamic_repo = repo.get_dynamic_repo()

    task =
      Task.async(fn ->
        run_maybe_in_transaction(parent, ref, repo, dynamic_repo, schema, migration, fun)
      end)

    if migrated_successfully?(ref, task.pid) do
      try do
        # The table with schema migrations can only be updated from
        # the parent process because it has a lock on the table
        verbose_schema_migration(repo, "update schema migrations", fn ->
          Yacto.Migration.SchemaMigration.up(repo, app, schema, migration.__migration_version__())
        end)
      catch
        kind, error ->
          Task.shutdown(task, :brutal_kill)
          :erlang.raise(kind, error, System.stacktrace())
      end
    end

    send(task.pid, ref)
    Task.await(task, :infinity)
  end

  defp migrated_successfully?(ref, pid) do
    receive do
      {^ref, :ok} -> true
      {^ref, _} -> false
      {:EXIT, ^pid, _} -> false
    end
  end

  defp run_maybe_in_transaction(parent, ref, repo, dynamic_repo, _schema, migration, fun) do
    repo.put_dynamic_repo(dynamic_repo)

    if migration.__migration__[:disable_ddl_transaction] ||
         not repo.__adapter__.supports_ddl_transaction? do
      send_and_receive(parent, ref, fun.())
    else
      {:ok, result} =
        repo.transaction(
          fn -> send_and_receive(parent, ref, fun.()) end,
          log: false,
          timeout: :infinity
        )

      result
    end
  catch
    kind, reason ->
      send_and_receive(parent, ref, {kind, reason, System.stacktrace()})
  end

  defp send_and_receive(parent, ref, value) do
    send(parent, {ref, value})
    receive do: (^ref -> value)
  end

  defp verbose_schema_migration(repo, reason, fun) do
    try do
      fun.()
    rescue
      error ->
        Logger.error("Could not #{reason} for #{repo}.")
        reraise error, System.stacktrace()
    end
  end

  defp attempt(repo, schema, migration, direction, operation, reference, opts) do
    if Code.ensure_loaded?(migration) and
         function_exported?(migration, operation, 1) do
      run(repo, schema, migration, direction, operation, reference, opts)
      :ok
    end
  end

  # Ecto.Migration.Runner.run

  defp run(repo, schema, migration, direction, operation, migrator_direction, opts) do
    version = migration.__migration_version__()

    level = Keyword.get(opts, :log, :info)
    sql = Keyword.get(opts, :log_sql, false)
    log = %{level: level, sql: sql}
    args = [self(), repo, migration, direction, migrator_direction, log]

    {:ok, runner} = Supervisor.start_child(Ecto.Migration.Supervisor, args)
    Ecto.Migration.Runner.metadata(runner, opts)

    log(level, "== Running #{version} #{inspect(migration)}.#{operation}/0 #{direction}")
    {time, _} = :timer.tc(fn -> perform_operation(repo, schema, migration, operation) end)
    log(level, "== Migrated #{version} in #{inspect(div(time, 100_000) / 10)}s")

    Ecto.Migration.Runner.stop()
  end

  defp perform_operation(repo, schema, migration, operation) do
    if function_exported?(repo, :in_transaction?, 0) and repo.in_transaction?() do
      if function_exported?(migration, :after_begin, 0) do
        migration.after_begin()
      end

      result = apply(migration, operation, [schema])

      if function_exported?(migration, :before_commit, 0) do
        migration.before_commit()
      end

      result
    else
      apply(migration, operation, [schema])
    end

    Ecto.Migration.Runner.flush()
  end

  defp log(false, _msg), do: :ok
  defp log(level, msg), do: Logger.log(level, msg)
end
