defmodule Mix.Tasks.Yacto.Gen.Migration do
  use Mix.Task

  @shortdoc "Generate migration file"

  @switches [version: :integer, prefix: :string, migration_dir: :string]

  def run(args) do
    Mix.Task.run("loadpaths", args)
    Mix.Task.run("app.start", args)

    case OptionParser.parse(args, switches: @switches) do
      {opts, [], _} ->
        app = Keyword.fetch!(Mix.Project.config(), :app)
        version = Keyword.get(opts, :version)
        prefix = Keyword.get(opts, :prefix)
        migration_dir = Keyword.get(opts, :migration_dir)

        _ = Application.load(app)

        schemas =
          Yacto.Migration.Util.get_all_schema(app, prefix)
          |> Enum.filter(fn schema ->
            Yacto.Migration.Util.need_gen_migration?(schema)
          end)

        validated =
          Yacto.Migration.Util.get_migration_files(app, migration_dir)
          |> Yacto.Migration.Util.load_migrations()
          |> Yacto.Migration.Util.sort_migrations()

        sorted_migrations =
          case validated do
            {:error, errors} ->
              Mix.raise("マイグレーションファイルが不正な状態になっています。:\n----\n" <> Enum.join(errors, "\n----\n"))

            {:ok, sorted_migrations} ->
              sorted_migrations
          end

        deleted_schemas =
          if length(sorted_migrations) != 0 do
            latest_migration = List.last(sorted_migrations)

            preview_schemas =
              Enum.map(latest_migration.module.__migration_structures__(), fn {a, _} -> a end)

            # preview_schemas に存在していて、schemas に存在していないモデルを探す
            preview_schemas -- schemas
          else
            []
          end

        Yacto.Migration.GenMigration.generate_migration(
          app,
          schemas,
          deleted_schemas,
          version,
          migration_dir,
          Application.get_env(:yacto, :migration, [])
        )

      {_, [_ | _], _} ->
        Mix.raise("Args error")

      {_, _, invalids} ->
        Mix.raise("Invalid arguments #{inspect(invalids)}")
    end
  end
end
