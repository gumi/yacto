defmodule Mix.Tasks.Yacto.Migrate do
  use Mix.Task
  require Logger

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

        migration_dir =
          Keyword.get(opts, :migration_dir, Yacto.Migration.Util.get_migration_dir(app))

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

        # メモ:
        # マイグレーションディレクトリに存在するディレクトリ（モジュール名）をすべて列挙する
        # ※各ファイル名にはバージョンとDB名と操作種別が付いている
        # 各ディレクトリのマイグレーションファイルに対して、
        #   - ファイル名から DB 名を取り出し、その DB 名が利用する Repo 一覧を調べる
        #   - その各 Repo に既に入っているバージョンを確認し、そのリポジトリに対してマイグレーション対象のファイルかどうかを調べる
        # マイグレーション対象のファイルをロードしてマイグレートし、バージョン情報を書き込む

        databases = Application.fetch_env!(:yacto, :databases)

        {schema_names, messages} = Yacto.Migration.File.list_migration_modules(migration_dir)
        for message <- messages do
          Logger.warn(message)
        end

        for repo <- repos do
          for schema_name <- schema_names do
            {migration_files, messages} = Yacto.Migration.File.list_migration_files(migration_dir, schema_name)
            for message <- messages do
              Logger.warn(message)
            end
            Yacto.Migration.Migrator.up2(app, repo, String.to_atom(schema_name), migration_dir, migration_files,
              db_opts: [databases: databases]
            )
          end
        end

      {_, [_ | _], _} ->
        Mix.raise("Args error")

      {_, _, invalids} ->
        Mix.raise("Invalid arguments #{inspect(invalids)}")
    end
  end
end
