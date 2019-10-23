defmodule Yacto.DB.Single do
  @behaviour Yacto.DB

  @impl Yacto.DB
  def repos(_dbname, config, _opts) do
    [config.repo]
  end

  @impl Yacto.DB
  def repo(_dbname, config, _opts) do
    config.repo
  end
end
