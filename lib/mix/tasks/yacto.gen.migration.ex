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
        Yacto.Migration.GenMigration.generate_migration(app, schemas, [], version)

      {_, [_ | _], _} ->
        Mix.raise("Args error")

      {_, _, invalids} ->
        Mix.raise("Invalid arguments #{inspect(invalids)}")
    end
  end
end
