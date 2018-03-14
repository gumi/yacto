defmodule Yacto.Query do
  require Ecto.Query

  @doc """
  a lock query expression `SELECT ... FOR UPDATE`
  """
  def for_update(queryable) do
    queryable |> Ecto.Query.lock("FOR UPDATE")
  end
end
