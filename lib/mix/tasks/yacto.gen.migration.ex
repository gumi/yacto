defmodule Mix.Tasks.Yacto.Gen.Migration do
  use Mix.Task

  @shortdoc "Generate migration file"

  @switches [version: :integer]

  def run(args) do
    Mix.Task.run("loadpaths", args)
    Mix.Task.run("app.start", args)

    case OptionParser.parse(args, switches: @switches) do
      {opts, [], _} ->
        app = Keyword.fetch!(Mix.Project.config(), :app)
        version = Keyword.get(opts, :version)

        _ = Application.load(app)
        schemas = Yacto.Migration.Util.get_all_schema(app)

        validated =
          Yacto.Migration.Util.get_migration_files(app)
          |> Yacto.Migration.Util.load_migrations()
          |> Yacto.Migration.Util.sort_migrations()

        case validated do
          {:error, errors} ->
            Mix.raise("マイグレーションファイルが不正な状態になっています。:\n----\n" <> Enum.join(errors, "\n----\n"))

          _ ->
            :ok
        end

        Yacto.Migration.GenMigration.generate_migration(
          app,
          schemas,
          [],
          version,
          nil,
          Application.get_env(:yacto, :migration, [])
        )

      {_, [_ | _], _} ->
        Mix.raise("Args error")

      {_, _, invalids} ->
        Mix.raise("Invalid arguments #{inspect(invalids)}")
    end
  end
end
