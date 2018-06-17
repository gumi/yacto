defmodule Yacto.DB do
  @callback repos(atom) :: [module]
  @callback repo(atom, any) :: module

  defp get_config(dbname) do
    databases = Application.fetch_env!(:yacto, :databases)
    Map.fetch!(databases, dbname)
  end

  def repos(dbname) do
    config = get_config(dbname)
    mod = config.module
    mod.repos(dbname)
  end

  def repo(dbname, dbkey \\ nil) do
    config = get_config(dbname)
    mod = config.module
    mod.repo(dbname, dbkey)
  end

  def all_repos() do
    databases = Application.fetch_env!(:yacto, :databases)

    repos =
      for {dbname, config} <- databases do
        mod = config.module
        mod.repos(dbname)
      end

    repos |> List.flatten() |> Enum.sort() |> Enum.dedup()
  end
end
