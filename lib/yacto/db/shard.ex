defmodule Yacto.DB.Shard do
  @behaviour Yacto.DB

  @impl Yacto.DB
  def repos(config) do
    config.repos
  end

  @impl Yacto.DB
  def repo(config, shard_key) when shard_key != nil do
    Enum.fetch!(config.repos, :erlang.phash2(shard_key, length(config.repos)))
  end
end
