defmodule Yacto.DB.Shard do
  @behaviour Yacto.DB

  use Memoize

  defmemop get_config(dbname) do
    databases = Application.fetch_env!(:yacto, :databases)
    config = Map.fetch!(databases, dbname)

    indexed_repos =
      config.repos
      |> Enum.with_index()
      |> Enum.map(fn {repo, index} -> {index, repo} end)
      |> Enum.into(%{})

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
  def repos(dbname) do
    config = get_config(dbname)
    config.repos
  end

  @impl Yacto.DB
  def repo(dbname, shard_key) when shard_key != nil do
    config = get_config(dbname)
    index = config.hash_fun.(shard_key, config.repo_length)
    Map.fetch!(config.indexed_repos, index)
  end
end
