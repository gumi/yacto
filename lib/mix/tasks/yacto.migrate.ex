defmodule Mix.Tasks.Yacto.Migrate do
  use Mix.Task

  @shortdoc "run migration"

  @switches [repo: :string, app: :string, migration_dir: :string]

  def run(args) do
    Mix.Task.run("loadpaths", args)
    Mix.Task.run("app.start", args)

    case OptionParser.parse(args, switches: @switches) do
      {opts, [], _} ->
        app =
          if Keyword.has_key?(opts, :app) do
            String.to_existing_atom(Keyword.get(opts, :app))
          else
            Mix.Project.config()[:app]
          end

        migration_dir = Keyword.get(opts, :migration_dir)

        if app == nil do
          Mix.raise("unspecified --app")
        end

        repos =
          case Keyword.fetch(opts, :repo) do
            :error -> Yacto.DB.all_repos()
            {:ok, repo} -> [Module.concat([repo])]
          end

        _ = Application.load(app)

        for repo <- repos do
          case repo.start_link() do
            {:ok, _} -> :ok
            {:error, {:already_started, _}} -> :ok
          end
        end

        schemas = Yacto.Migration.Util.get_all_schema(app)

        migrations =
          Yacto.Migration.Util.get_migration_files(app, migration_dir)
          |> Yacto.Migration.Util.load_migrations()

        databases = Application.fetch_env!(:yacto, :databases)

        for repo <- repos do
          Yacto.Migration.Migrator.up(app, repo, schemas, migrations,
            db_opts: [databases: databases]
          )
        end

      {_, [_ | _], _} ->
        Mix.raise("Args error")

      {_, _, invalids} ->
        Mix.raise("Invalid arguments #{inspect(invalids)}")
    end
  end
end
