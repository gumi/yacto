defmodule Yacto.DB.Single do
  @behaviour Yacto.DB

  @impl Yacto.DB
  def repos(config) do
    [config.repo]
  end

  @impl Yacto.DB
  def repo(config, _) do
    config.repo
  end
end
