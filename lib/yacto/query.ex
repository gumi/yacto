defmodule Yacto.Query do
  @moduledoc """
  クエリに関する便利関数を提供するモジュール
  """

  require Ecto.Query

  @doc """
  `SELECT ... FOR UPDATE` のクエリを発行する
  """
  def for_update(queryable) do
    queryable |> Ecto.Query.lock("FOR UPDATE")
  end
end
