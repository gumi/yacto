defmodule Yacto.DB.Shard do
  @behaviour Yacto.DB

  use Memoize

  defmemop get_config(config) do
    indexed_repos =
      config.repos
      |> Enum.with_index()
      |> Enum.map(fn {repo, index} -> {index, repo} end)
      |> Enum.into(%{})

    # 設定にハッシュ関数が指定されていた場合は、そちらを利用する。
    # デフォルトは :erlang.phash2/2 となる。
    {m, f, a} =
      case Map.fetch(config, :hash_mfa) do
        :error -> {:erlang, :phash2, []}
        {:ok, {_, _, _} = mfa} -> mfa
      end

    hash_fun = fn shard_key, num ->
      apply(m, f, [shard_key, num | a])
    end

    %{
      repos: config.repos,
      indexed_repos: indexed_repos,
      repo_length: length(config.repos),
      hash_fun: hash_fun
    }
  end

  @impl Yacto.DB
  def repos(_dbname, config, _opts) do
    config = get_config(config)
    config.repos
  end

  @impl Yacto.DB
  def repo(_dbname, config, opts) do
    shard_key = Keyword.fetch!(opts, :shard_key)
    config = get_config(config)
    index = config.hash_fun.(shard_key, config.repo_length)
    Map.fetch!(config.indexed_repos, index)
  end
end
