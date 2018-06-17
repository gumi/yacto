defmodule Yacto.DB.Single do
  @behaviour Yacto.DB

  defp get_config(dbname) do
    databases = Application.fetch_env!(:yacto, :databases)
    Map.fetch!(databases, dbname)
  end

  @impl Yacto.DB
  def repos(dbname) do
    [get_config(dbname).repo]
  end

  @impl Yacto.DB
  def repo(dbname, _) do
    get_config(dbname).repo
  end
end
