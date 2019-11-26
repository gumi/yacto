defmodule Yacto.Migration.File do
  defstruct [
    :version,
    :dbname,
    # :create, :change, :delete のどれか
    :operation,
    :datetime_str,
    :path
  ]

  # {dirs, [unexpected_messages]}
  def list_migration_modules(migration_dir) do
    dirs = Path.wildcard(Path.join(migration_dir, "*"))
    {dirs, files} = Enum.split_with(dirs, &File.dir?/1)
    {dirs, unexpected_dirs} = Enum.split_with(dirs, &String.starts_with?(&1, "Elixir."))

    file_messages =
      Enum.map(files, &"#{&1} is not directory in migration directory #{migration_dir}")

    dir_messages =
      Enum.map(
        unexpected_dirs,
        &"The directory #{&1} is not Elixir module in migration directory #{migration_dir}"
      )

    messages = file_messages ++ dir_messages

    {dirs, messages}
  end

  def list_migration_files(migration_dir, module_string) do
    files = Path.wildcard(Path.join(migration_dir, module_string, "*"))
    results = Enum.map(files, &path_to_structure/1)

    {oks, errors} =
      Enum.split_with(files, fn
        {:ok, _} -> true
        {:error, _} -> false
      end)
    files = Enum.map(oks, fn {:ok, r} -> r end)
  end

  defp path_to_structure(path) do
    try do
      filename = Path.basename(path)

      if not File.regular?(filename) do
        throw("#{filename} is not a regular file")
      end

      if not String.ends_with?(".exs") do
        throw("#{filename} is not an elixir script file")
      end

      # 0001-dbname-create-2019_11_26_170846.exs

      # .exs 削除
      filename_noext = String.slice(filename, 0..-5)
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
         path: path
       }}
    catch
      :throw, message -> {:error, message}
    end
  end

  def load_migration(migration_file) do
  end
end
