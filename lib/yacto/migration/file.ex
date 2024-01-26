defmodule Yacto.Migration.File do
  defstruct [
    :version,
    :dbname,
    # :create, :change, :delete のどれか
    :operation,
    :datetime_str,
    :path,
    :schema_name
  ]

  # {module_strings, [unexpected_messages]}
  def list_migration_modules(migration_dir) do
    dirs = Path.wildcard(Path.join(migration_dir, "*"))
    {dirs, files} = Enum.split_with(dirs, &File.dir?/1)
    dirs = Enum.map(dirs, &Path.relative_to(&1, migration_dir))
    {dirs, unexpected_dirs} = Enum.split_with(dirs, &String.starts_with?(&1, "Elixir."))

    file_messages =
      Enum.map(files, &"#{&1} is not directory in migration directory #{migration_dir}")

    dir_messages =
      Enum.map(
        unexpected_dirs,
        &"The directory #{&1} is not Elixir module in migration directory #{migration_dir}"
      )

    messages = file_messages ++ dir_messages

    {Enum.sort(dirs), messages}
  end

  @spec list_migration_files(String.t(), String.t()) :: {[%Yacto.Migration.File{}], [String.t()]}
  def list_migration_files(migration_dir, module_string) when is_binary(module_string) do
    files = Path.wildcard(Path.join([migration_dir, module_string, "*"]))

    results =
      Enum.map(files, &path_to_structure(migration_dir, Path.relative_to(&1, migration_dir)))

    {oks, errors} =
      Enum.split_with(results, fn
        {:ok, _} -> true
        {:error, _} -> false
      end)

    files = Enum.map(oks, fn {:ok, r} -> r end)
    errors = Enum.map(errors, fn {:error, e} -> e end)
    {Enum.sort_by(files, & &1.version), errors}
  end

  @spec check_migrations([]) :: :ok | {:error, [String.t()]}
  def check_migrations(migration_dir) do
    {modules, _} = list_migration_modules(migration_dir)

    filess =
      Enum.map(modules, fn mod ->
        {files, _} = list_migration_files(migration_dir, mod)
        files
      end)

    messages =
      Enum.reduce(filess, [], fn files, messages ->
        case check_migration_files(files) do
          :ok -> messages
          {:error, ms} -> messages ++ ms
        end
      end)

    if length(messages) != 0 do
      {:error, messages}
    else
      :ok
    end
  end

  @spec check_migration_files([%Yacto.Migration.File{}]) :: :ok | {:error, [String.t()]}
  def check_migration_files(files)

  def check_migration_files([]) do
    :ok
  end

  def check_migration_files([_ | _] = files) do
    try do
      # 全部同じスキーマに対するマイグレーションファイルか
      xs = Enum.group_by(files, & &1.schema_name)

      if map_size(xs) >= 2 do
        schema_names = Enum.map(xs, fn {name, _} -> name end)
        throw(["複数のスキーマ名が含まれています: #{inspect(schema_names)}"])
      end

      # 全部異なるパスになっているか
      xs =
        files
        |> Enum.group_by(& &1.path)
        |> Enum.filter(fn {_, files} -> length(files) != 1 end)

      if length(xs) != 0 do
        messages = Enum.map(xs, fn {path, _} -> "同じファイルパスになっています: #{path}" end)
        throw(messages)
      end

      # 同じバージョンのファイルが存在しないか
      xs =
        files
        |> Enum.group_by(& &1.version)
        |> Enum.filter(fn {_, files} -> length(files) != 1 end)

      if length(xs) != 0 do
        messages =
          xs
          |> Enum.sort_by(fn {version, _} -> version end)
          |> Enum.map(fn {_, files} ->
            "同じバージョンのファイルが存在しています: #{inspect(Enum.map(files, & &1.path))}"
          end)

        throw(messages)
      end

      # 0 から順番になっているか
      files = Enum.sort_by(files, & &1.version)

      messages =
        files
        |> Enum.with_index()
        |> Enum.map(fn {file, index} ->
          if file.version != index do
            "ファイルが0からの連番になっていません。期待していたバージョンは #{pad4(index)} です: #{file.path}"
          else
            nil
          end
        end)
        |> Enum.filter(fn x -> x != nil end)

      if length(messages) != 0 do
        throw(messages)
      end

      :ok
    catch
      :throw, messages -> {:error, messages}
    end
  end

  # {%Yacto.Migration.File{} | nil, [error]}
  def get_latest_migration_file(migration_dir, module_string) when is_binary(module_string) do
    {files, errors} = list_migration_files(migration_dir, module_string)

    case files do
      [] -> {nil, errors}
      _ -> {List.last(files), errors}
    end
  end

  defp path_to_structure(migration_dir, relative_path) do
    try do
      path = Path.join(migration_dir, relative_path)
      filename = Path.basename(relative_path)
      dirname = relative_path |> Path.dirname() |> Path.basename()

      if not File.regular?(path) do
        throw("#{relative_path} is not a regular file")
      end

      if not String.ends_with?(filename, ".exs") do
        throw("#{filename} is not an elixir script file")
      end

      if not String.starts_with?(dirname, "Elixir.") do
        throw("#{relative_path} directory name is not an elixir module name")
      end

      # 0001-dbname-create-2019_11_26_170846.exs

      # .exs 削除
      filename_noext = String.slice(filename, 0..-5//1)
      parts = String.split(filename_noext, "-")

      if length(parts) != 4 do
        throw("#{filename} is a invalid filename")
      end

      [version_str, dbname, operation, datetime_str] = parts

      if not String.match?(version_str, ~r/[0-9]{4}/) do
        # 4桁の数字でない
        throw("#{filename} is a invalid filename (invalid version #{version_str})")
      end

      version = String.to_integer(version_str)

      operation =
        case operation do
          "create" -> :create
          "change" -> :change
          "delete" -> :delete
          _ -> throw("#{filename} is a invalid filename (invalid operation #{operation}")
        end

      {:ok,
       %__MODULE__{
         version: version,
         dbname: String.to_atom(dbname),
         operation: operation,
         datetime_str: datetime_str,
         path: relative_path,
         schema_name: dirname
       }}
    catch
      :throw, message -> {:error, message}
    end
  end

  @spec load_migration_module(String.t(), %Yacto.Migration.File{}) ::
          {:ok, module()} | {:error, any()}
  def load_migration_module(migration_dir, %__MODULE__{} = migration_file) do
    path = Path.join(migration_dir, migration_file.path)

    modules = Code.compile_file(path)

    if length(modules) == 0 do
      {:error, "Module not found: #{path}"}
    else
      if length(modules) >= 2 do
        {:error, "Multiple module found: #{path}"}
      else
        [{mod, _}] = modules

        if not function_exported?(mod, :__migration__, 1) do
          {:error, "The module is not Yacto migration module: #{path}"}
        else
          {:ok, mod}
        end
      end
    end
  end

  def new(schema_name, version, dbname, operation, now) when is_binary(schema_name) do
    datetime_str =
      now
      # 2020-02-16T01:10:20+00:00
      |> DateTime.to_iso8601()
      # 2020-02-16T01:10:20
      |> String.slice(0, 19)
      # 2020-02-16T011020
      |> String.replace(":", "")
      # 2020-02-16_011020
      |> String.replace("T", "_")
      # 2020_02_16_011020
      |> String.replace("-", "_")

    path = Path.join(schema_name, "#{pad4(version)}-#{dbname}-#{operation}-#{datetime_str}.exs")

    %__MODULE__{
      version: version,
      dbname: dbname,
      operation: operation,
      datetime_str: datetime_str,
      path: path,
      schema_name: schema_name
    }
  end

  def save(content, migration_dir, %__MODULE__{} = migration_file) do
    path = Path.join(migration_dir, migration_file.path)

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(path, content) do
      {:ok, path}
    end
  end

  defp pad4(i) when i < 10, do: <<?0, ?0, ?0, ?0 + i>>
  defp pad4(i) when i < 100, do: <<?0, ?0, ?0 + div(i, 10), ?0 + rem(i, 10)>>

  defp pad4(i) when i < 1000,
    do: <<?0, ?0 + div(i, 100), ?0 + rem(div(i, 10), 10), ?0 + rem(i, 10)>>

  defp pad4(i), do: to_string(i)
end
