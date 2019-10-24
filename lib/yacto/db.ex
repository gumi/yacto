defmodule Yacto.DB do
  @moduledoc """
  Yacto の repo を取得するためのモジュール

  水平分割をしている場合、シャーディングキーによって利用する repo が変わるため、
  直接 repo を利用するのではなく、`Yacto.repo/{2-3}` を利用する必要がある。
  """

  @callback repos(atom, any, list) :: [module]
  @callback repo(atom, any, list) :: module

  defp get_config(dbname, databases) do
    databases = databases || Application.fetch_env!(:yacto, :databases)
    Map.fetch!(databases, dbname)
  end

  def repos(dbname, opts \\ []) do
    databases = Keyword.get(opts, :databases)
    config = get_config(dbname, databases)
    mod = config.module
    mod.repos(dbname, config, opts)
  end

  def repo(dbname, opts \\ []) do
    databases = Keyword.get(opts, :databases)
    config = get_config(dbname, databases)
    mod = config.module
    mod.repo(dbname, config, opts)
  end

  def all_repos(opts \\ []) do
    databases = Keyword.get(opts, :databases)
    databases = databases || Application.fetch_env!(:yacto, :databases)

    repos =
      for {dbname, config} <- databases do
        mod = config.module
        mod.repos(dbname, config, opts)
      end

    repos |> List.flatten() |> Enum.sort() |> Enum.dedup()
  end
end
