defmodule Yacto.Shard.Router do
  @behaviour Yacto.Migration.Router

  def allow_migrate(schema, repo, opts) do
    if function_exported?(schema, :__shard_repo__, 0) do
      repo in schema.__shard_repo__().__repos__()
    else
      schemas = opts[:schemas] |> Enum.filter(&function_exported?(&1, :__shard_repo__, 0))
      repo_for_shard = schemas |> Enum.map(fn schema -> repo in schema.__shard_repo__().__repos__() end) |> Enum.any?()
      if repo_for_shard do
        false
      else
        nil
      end
    end
  end
end
