defmodule Yacto.Migration.Util do
  def get_migration_dir_for_gen(migration_dir \\ nil) do
    migration_dir || "priv/migrations"
  end

  def get_migration_dir(app, migration_dir \\ nil) do
    migration_dir || Application.app_dir(app, "priv/migrations")
  end

  def get_migration_files(app, migration_dir \\ nil) do
    dir = get_migration_dir(app, migration_dir)
    Path.wildcard(Path.join(dir, '*.exs'))
  end

  def validate_version(migration_version) do
    # YYYYMMDDhhmmss
    if String.length(Integer.to_string(migration_version)) != 14 do
      raise "Migration version must be specified format YYYYMMDDhhmmss"
    end
  end

  def get_migration_filename(app, migration_version) do
    validate_version(migration_version)
    strmig = Integer.to_string(migration_version)
    year = String.slice(strmig, 0..3)
    month = String.slice(strmig, 4..5)
    day = String.slice(strmig, 6..7)
    hour = String.slice(strmig, 8..9)
    minute = String.slice(strmig, 10..11)
    second = String.slice(strmig, 12..13)

    "#{year}-#{month}-#{day}T#{hour}#{minute}#{second}_#{app}.exs"
  end

  def get_migration_path_for_gen(app, migration_version, migration_dir \\ nil) do
    dir = get_migration_dir_for_gen(migration_dir)
    filename = get_migration_filename(app, migration_version)
    Path.join(dir, filename)
  end

  def get_migration_path(app, migration_version, migration_dir \\ nil) do
    dir = get_migration_dir(app, migration_dir)
    filename = get_migration_filename(app, migration_version)
    Path.join(dir, filename)
  end

  def is_schema_module?(mod), do: function_exported?(mod, :__schema__, 1)

  def get_all_schema(app, prefix \\ nil) do
    mods = Application.spec(app, :modules)

    Enum.filter(mods, fn mod ->
      Code.ensure_loaded(mod)
      exported = is_schema_module?(mod)

      if !exported do
        false
      else
        if prefix == nil do
          true
        else
          # prefix が指定されてる場合、条件に一致する schema だけ返す（デバッグ用）
          List.starts_with?(Module.split(mod), Module.split(Module.concat([prefix])))
        end
      end
    end)
  end

  def need_gen_migration?(schema) do
    case function_exported?(schema, :gen_migration?, 0) do
      true -> schema.gen_migration?
      false -> true
    end
  end

  def is_migration_module?(mod), do: function_exported?(mod, :__migration__, 0)

  def load_migrations(migration_files) do
    for migration_file <- migration_files,
        {module, _} <- Code.load_file(migration_file),
        is_migration_module?(module) do
      %{
        file: migration_file,
        module: module,
        version: module.__migration_version__(),
        preview_version:
          if(function_exported?(module, :__migration_preview_version__, 0),
            do: module.__migration_preview_version__(),
            else: :unspecified
          )
      }
    end
  end

  def allow_migrate?(schema, repo, opts \\ []) do
    Code.ensure_loaded(schema)

    if function_exported?(schema, :dbname, 0) do
      dbname = schema.dbname()
      repos = Yacto.DB.repos(dbname, opts)
      repo in repos
    else
      false
    end
  end

  @doc """
  マイグレーションファイルが正しく順序付けされているか調べて、正しい順序のマイグレーション情報を返す

  `migrations` には `%{file: ファイル名, module: モジュール, version: マイグレーションバージョン, preview_version: 直前のマイグレーションバージョン}` のリストを渡すこと。
  旧マイグレーションファイルには直前のマイグレーションバージョンが存在しないが、その場合には `:unspecified` を指定すること。
  """
  def sort_migrations(migrations) do
    migrations = migrations |> Enum.sort_by(& &1.version)

    migration_dic =
      migrations |> Enum.map(fn migration -> {migration.version, migration} end) |> Enum.into(%{})

    # 旧バージョンのマイグレーションファイルの一覧
    unspecified_migrations =
      migrations
      |> Enum.filter(&(&1.preview_version == :unspecified))
      |> Enum.sort_by(& &1.version)

    try do
      if length(migrations) != 0 do
        # 同じバージョンがあったらエラー
        errors =
          for {migration1, migration2} <- Enum.zip(migrations, tl(migrations)),
              migration1.version == migration2.version do
            "同じバージョン #{migration1.version} があります。#{migration1.file} と #{migration2.file}"
          end

        if length(errors) != 0 do
          throw({:error, errors})
        end
      end

      # 存在しないバージョンがあったらエラー
      errors =
        for migration <- migrations,
            is_integer(migration.preview_version),
            not Map.has_key?(migration_dic, migration.preview_version) do
          "#{migration.file} が指定している直前のバージョン #{migration.preview_version} が存在しません"
        end

      if length(errors) != 0 do
        throw({:error, errors})
      end

      # 誰から参照されているかを調べる
      referenced_migrations =
        migrations
        |> Enum.reduce([], fn migration, result ->
          # {自身のバージョン, 自身を参照しているバージョン} のリストを作る
          if is_integer(migration.preview_version) do
            [{migration.preview_version, migration.version} | result]
          else
            result
          end
        end)
        |> Enum.reduce(%{}, fn {version, referenced_version}, result ->
          # [{自身のバージョン, 自身を参照しているバージョン}] から
          # %{自身のバージョン: [自身を参照しているバージョン]} を作る
          if version not in result do
            Map.put_new(result, version, [referenced_version])
          else
            update_in(result[version], fn vers -> [referenced_version | vers] end)
          end
        end)

      # ２個以上参照されている場合は正しくマイグレーションファイルが生成されていない
      errors =
        for {version, referenced_versions} <- referenced_migrations,
            length(referenced_versions) >= 2 do
          files =
            referenced_versions |> Enum.map(&"- #{migration_dic[&1].file}") |> Enum.join("\n")

          "直前のバージョンが #{migration_dic[version].file} であるマイグレーションファイルが複数あります。\n#{files}"
        end

      if length(errors) != 0 do
        throw({:error, errors})
      end

      # ルートとなるバージョンが１個ではない
      root =
        migrations
        |> Enum.filter(fn migration -> migration.preview_version != :unspecified end)
        |> Enum.filter(fn migration ->
          length(Map.get(referenced_migrations, migration.version, [])) == 0
        end)

      if length(root) >= 2 do
        files = root |> Enum.map(fn migration -> "- #{migration.file}" end) |> Enum.join("\n")

        message =
          "ルートが一意に決定できません。\n" <>
            "新旧のマイグレーションファイルが混ざっている可能性があります。\n" <>
            "ルート候補:\n" <> files

        throw({:error, [message]})
      end

      if map_size(referenced_migrations) != 0 && length(root) == 0 do
        throw({:error, ["マイグレーションファイルの指定が循環しています。"]})
      end

      # 全てが綺麗につながったソート済みのマイグレーション情報が返される
      sorted_migrations =
        if length(root) == 0 do
          unspecified_migrations
        else
          # ルートから辿って順序どおりに作っていく
          [root] = root

          f = fn f, version, results ->
            if not is_integer(version) do
              results
            else
              migration = migration_dic[version]
              f.(f, migration.preview_version, [migration | results])
            end
          end

          sorted_migrations = f.(f, root.version, [])

          preview_version = hd(sorted_migrations).preview_version

          case preview_version do
            # 最後の要素の前のバージョンが nil なら完成
            nil ->
              # この場合は旧バージョンのマイグレーションファイルは存在しないはず
              if length(unspecified_migrations) != 0 do
                files =
                  unspecified_migrations
                  |> Enum.map(fn migration -> "- #{migration.file}" end)
                  |> Enum.join("\n")

                throw({:error, ["用途不明のマイグレーションファイルが存在しています。\n" <> files]})
              end

              sorted_migrations

            # :unspecified なら、unspecified_migrations と結合する
            :unspecified ->
              # unspecified_migrations の長さは絶対 1 以上のはず
              if length(unspecified_migrations) == 0 do
                throw({:error, ["何かが間違っている"]})
              end

              # この２つは同じものを参照しているはず
              if List.last(unspecified_migrations).version != hd(sorted_migrations).version do
                message =
                  "旧バージョンのマイグレーションファイルの順序が間違っています。\n" <>
                    "最新は #{hd(sorted_migrations).file} であるはずなのに #{
                      List.last(unspecified_migrations).file
                    } になっています。"

                throw({:error, [message]})
              end

              unspecified_migrations ++ tl(sorted_migrations)

            # ここに来るのはおかしい
            _ ->
              throw({:error, ["何かが間違っている"]})
          end
        end

      {:ok, sorted_migrations}
    catch
      error -> error
    end
  end
end
