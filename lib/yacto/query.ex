defmodule Yacto.Query do
  require Ecto.Query

  defp pop!(kwargs, key) do
    value = Keyword.fetch!(kwargs, key)
    kwargs = Keyword.delete(kwargs, key)
    {value, kwargs}
  end

  defp ensure_empty([]), do: :ok
  defp ensure_empty(kwargs) do
    raise "unnecessary keywords: #{inspect kwargs}"
  end

  def get(schema, repo, kwargs) do
    {lock, kwargs} = pop!(kwargs, :lock)
    {lookup, kwargs} = pop!(kwargs, :lookup)
    {opts, kwargs} = Keyword.pop(kwargs, :opts, [])
    ensure_empty(kwargs)

    query = schema
            |> Ecto.Query.where(^lookup)
    query = if lock do
              query |> Ecto.Query.lock("FOR UPDATE")
            else
              query
            end
    query |> repo.one!(opts)
  end

  def get_or_new(schema, repo, kwargs) do
    {lookup, kwargs} = pop!(kwargs, :lookup)
    {defaults, kwargs} = Keyword.pop(kwargs, :defaults, [])
    ensure_empty(kwargs)

    opts = Keyword.get(kwargs, :opts, [])

    query = schema
            |> Ecto.Query.where(^lookup)
    case repo.one(query, opts) do
      nil ->
        struct(schema, Keyword.merge(lookup, defaults))
      schema ->
        schema
    end
  end

  # # 作成（既に有れば例外、ロック有り）
  # player = Gscx.Query.insert(Gscx.Player.Shcema.Player, Gscx.Repo.get_player(player_id), player_id: player_id)

  # # 作成（既に有れば更新、ロック有り）
  # player = Gscx.Query.insert_or_update(Gscx.Player.Shcema.Player, Gscx.Repo.get_player(player_id), lookup: [player_id: player_id], set: [name: name])

  # # 更新
  # player = %{name: "foo" | player}
  # player = Gscx.Query.update(player, Gscx.Repo.get_player(player_id))
end
