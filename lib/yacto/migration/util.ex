defmodule Yacto.Migration.Util do
  def get_migration_dir_for_gen() do
    "priv/migrations"
  end

  def get_migration_dir(app) do
    Application.app_dir(app, "priv/migrations")
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
end
