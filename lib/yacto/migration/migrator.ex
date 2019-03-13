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

    * `:log` - the level to use for logging. Defaults to `:info`.
      Can be any of `Logger.level/0` values or `false`.
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
    run_maybe_in_transaction(repo, migration, fn ->
      run(repo, schema, migration, :forward, :change, :up, opts)

      verbose_schema_migration(repo, "update schema migrations", fn ->
        Yacto.Migration.SchemaMigration.up(repo, app, schema, migration.__migration_version__())
      end)
    end)
  end

  defp run(repo, schema, migration, direction, operation, migrator_direction, opts) do
    level = Keyword.get(opts, :log, :info)
    sql = Keyword.get(opts, :log_sql, false)
    log = %{level: level, sql: sql}
    args = [self(), repo, direction, migrator_direction, log]

    {:ok, runner} = Supervisor.start_child(Ecto.Migration.Supervisor, args)
    Ecto.Migration.Runner.metadata(runner, opts)

    message =
      "== Running #{inspect(migration)}.#{operation}(#{inspect(schema)}) " <>
        "#{direction} to [#{inspect(repo)}]"

    log(level, message)

    {time1, _} = :timer.tc(migration, operation, [schema])
    {time2, _} = :timer.tc(&Ecto.Migration.Runner.flush/0, [])
    time = time1 + time2
    log(level, "== Migrated in #{inspect(div(time, 100_000) / 10)}s")

    Ecto.Migration.Runner.stop()
  end

  defp run_maybe_in_transaction(repo, module, fun) do
    cond do
      module.__migration__[:disable_ddl_transaction] ->
        fun.()

      repo.__adapter__.supports_ddl_transaction? ->
        repo.transaction(fun, log: false, timeout: :infinity)

      true ->
        fun.()
    end
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

  defp log(false, _msg), do: :ok
  defp log(level, msg), do: Logger.log(level, msg)
end
