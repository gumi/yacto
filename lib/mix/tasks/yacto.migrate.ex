defmodule Mix.Tasks.Yacto.Migrate do
  use Mix.Task

  @shortdoc "run migration"

  @switches [repo: :string,
             app: :string]

  def run(args) do
    Mix.Task.run "loadpaths", args
    Mix.Task.run "app.start", args
    case OptionParser.parse(args, switches: @switches) do
      {opts, [], _} ->
        repo = Module.concat("Elixir", Keyword.fetch!(opts, :repo))
        app = if Keyword.has_key?(opts, :app) do
                String.to_existing_atom(Keyword.get(opts, :app))
              else
                Mix.Project.config[:app]
              end
        if app == nil do
          Mix.raise "unspecified --app"
        end

        _ = Application.load(app)
        {:ok, _} = repo.start_link()

        schemas = Yacto.Migration.Util.get_all_schema(app)
        migrations = Yacto.Migration.Util.get_migration_files(app) |> Yacto.Migration.Util.load_migrations()
        Yacto.Migration.Migrator.up(app, repo, schemas, migrations)
      {_, [_ | _], _} ->
        Mix.raise "Args error"
      {_, _, invalids} ->
        Mix.raise "Invalid arguments #{inspect invalids}"
    end
  end
end
