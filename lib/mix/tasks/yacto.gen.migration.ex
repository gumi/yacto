defmodule Mix.Tasks.Yacto.Gen.Migration do
  use Mix.Task

  @shortdoc "Generate migration file"

  @switches [app: :string,
             version: :integer]

  def run(args) do
    Mix.Task.run "loadpaths", args
    Mix.Task.run "app.start", args
    case OptionParser.parse(args, switches: @switches) do
      {opts, [], _} ->
        app = if Keyword.has_key?(opts, :app) do
                String.to_existing_atom(Keyword.get(opts, :app))
              else
                Mix.Project.config[:app]
              end
        if app == nil do
          Mix.raise "unspecified --app"
        end
        version = Keyword.get(opts, :version)

        _ = Application.load(app)
        schemas = Yacto.Migration.Util.get_all_schema(app)
        Yacto.Migration.GenMigration.generate_migration(app, schemas, [], version)
      {_, [_ | _], _} ->
        Mix.raise "Args error"
      {_, _, invalids} ->
        Mix.raise "Invalid arguments #{inspect invalids}"
    end
  end
end
