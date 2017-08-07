defmodule Yacto.Migration.Util do
  defp apply_myers_difference(_list, [], result) do
    result |> Enum.reverse() |> Enum.concat()
  end

  defp apply_myers_difference(list, [{:eq, vs} | diff], result) do
    if Enum.take(list, length(vs)) != vs do
      raise "invalid source"
    end
    list = Enum.drop(list, length(vs))
    apply_myers_difference(list, diff, [vs | result])
  end

  defp apply_myers_difference(list, [{:ins, vs} | diff], result) do
    apply_myers_difference(list, diff, [vs | result])
  end

  defp apply_myers_difference(list, [{:del, vs} | diff], result) do
    if Enum.take(list, length(vs)) != vs do
      raise "invalid source"
    end
    list = Enum.drop(list, length(vs))
    apply_myers_difference(list, diff, result)
  end

  def apply_myers_difference(list, diff) do
    apply_myers_difference(list, diff, [])
  end

  def get_migration_dir(app, migration_dir \\ nil) do
    migration_dir || Application.app_dir(app, "priv/migrations")
  end

  def get_migration_files(app, migration_dir \\ nil) do
    dir = get_migration_dir(app, migration_dir)
    Path.wildcard(Path.join(dir, '*.exs'))
  end

  def get_migration_path(app, migration_version, migration_dir \\ nil) do
    dir = get_migration_dir(app, migration_dir)
    filename = "#{migration_version}_#{app}.exs"
    Path.join(dir, filename)
  end

  def is_schema_module?(mod), do: function_exported?(mod, :__schema__, 1)

  def get_all_schema(app, prefix \\ nil) do
    mods = Application.spec(app, :modules)
    Enum.filter(mods,
                fn mod ->
                  Code.ensure_loaded(mod)
                  exported = is_schema_module?(mod)
                  if !exported do
                    false
                  else
                    if prefix == nil do
                      true
                    else
                      String.starts_with?(Atom.to_string(mod), Atom.to_string(prefix))
                    end
                  end
                end)
  end

  def is_migration_module?(mod), do: function_exported?(mod, :__migration__, 0)

  def load_migrations(migration_files) do
    for migration_file <- migration_files,
        {module, _} <- Code.load_file(migration_file),
        is_migration_module?(module) do
      module
    end
  end

  def allow_migrate?(schema, repo) do
    Code.ensure_loaded(schema)
    if function_exported?(schema, :dbname, 0) do
      dbname = schema.dbname()
      repos = Yacto.DB.repos(dbname)
      repo in repos
    else
      false
    end
  end
end
