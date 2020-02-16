defmodule Mix.Tasks.Yacto.Gen.Migration2 do
  require Logger
  use Mix.Task

  @shortdoc "Generate migration file"

  @switches [prefix: :string, migration_dir: :string]

  def run(args) do
    Mix.Task.run("loadpaths", args)
    Mix.Task.run("app.start", args)

    case OptionParser.parse(args, switches: @switches) do
      {opts, [], _} ->
        app = Keyword.fetch!(Mix.Project.config(), :app)
        prefix = Keyword.get(opts, :prefix)

        migration_dir =
          Keyword.get(opts, :migration_dir, Yacto.Migration.Util.get_migration_dir_for_gen())

        _ = Application.load(app)

        {:ok, now} = DateTime.now("Etc/UTC")

        schemas =
          Yacto.Migration.Util.get_all_schema(app, prefix)
          |> Enum.filter(fn schema ->
            Yacto.Migration.Util.need_gen_migration?(schema)
          end)

        for schema <- schemas do
          {migration_file, messages} = Yacto.Migration.File.get_latest_migration_file(migration_dir, to_string(schema))
          for message <- messages do
            Logger.warn(message)
          end

          migration =
            case migration_file do
              nil -> nil
              _ ->
                {:ok, migration} = Yacto.Migration.File.load_migration_module(migration_dir, migration_file)
                migration
            end

          result = Yacto.Migration.GenMigration2.generate(
            schema,
            migration,
            Application.get_env(:yacto, :migration, [])
          )
          case result do
            # not changed
            :not_changed ->
              Logger.info("A schema #{schema} is not changed. The migration file is not generated.")
              :ok
            # generated
            {type, str, version} ->
              dbname = schema.dbname()
              operation =
                case type do
                  :created -> :create
                  :changed -> :change
                  :deleted -> :delete
                end
              migration_file = Yacto.Migration.File.new(schema, version, dbname, operation, now)

              path = Path.join(migration_dir, migration_file.path)
              File.mkdir_p!(Path.dirname(path))
              File.write!(path, str)
              Logger.info("Generated a migration file #{path} for schema #{schema}")
          end
        end

        # module_names = Yacto.Migration.File.list_migration_modules(migration_dir)

      {_, [_ | _], _} ->
        Mix.raise("Args error")

      {_, _, invalids} ->
        Mix.raise("Invalid arguments #{inspect(invalids)}")
    end
  end
end
