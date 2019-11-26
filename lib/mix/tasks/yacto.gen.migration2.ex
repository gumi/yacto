defmodule Mix.Tasks.Yacto.Gen.Migration2 do
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

        # メモ:
        # 現在のアプリケーションに存在するスキーマ一覧を列挙する
        # マイグレーションディレクトリに存在するディレクトリ（モジュール名）をすべて列挙する
        # 最新バージョンの操作種別が delete でない、有効なマイグレーションファイルを取り出す
        # スキーマ一覧からマイグレーションファイルを作る
        # (有効なマイグレーションファイル - スキーマ一覧) して、削除されたスキーマ用のマイグレーションファイルを作る
        schemas =
          Yacto.Migration.Util.get_all_schema(app, prefix)
          |> Enum.filter(fn schema ->
            Yacto.Migration.Util.need_gen_migration?(schema)
          end)

        for schema <- schemas do
          migration = get_latest_migration(schema, migration_dir)

          Yacto.Migration.GenMigration2.generate(
            schema,
            migration,
            Application.get_env(:yacto, :migration, [])
          )
        end

      {_, [_ | _], _} ->
        Mix.raise("Args error")

      {_, _, invalids} ->
        Mix.raise("Invalid arguments #{inspect(invalids)}")
    end
  end

  defp extract_module(file) do
    modules = Code.load_file(file)

    if length(modules) == 0 do
      raise "Module not found: #{file}"
    end

    if length(modules) >= 2 do
      raise "Multiple module found: #{file}"
    end

    [{mod, _}] = modules

    if not function_exported?(mod, :__migration_structure__, 0) do
      raise "The module is not Yacto migration module: #{file}"
    end

    mod
  end

  # 最新のマイグレーションモジュールを取得する
  # マイグレーションモジュールが１件も存在しなかった場合は `nil` を返す。
  defp get_latest_migration(schema, migration_dir) do
    paths =
      Path.wildcard(Path.join([migration_dir, to_string(schema.__base_schema__()), '*.exs']))

    if paths == [] do
      nil
    else
      # 名前を降順でソートして最新の１件だけ取り出す
      [path | _] = Enum.sort_by(paths, &Path.basename/1, &(&1 >= &2))

      extract_module(path)
    end
  end
end
