defmodule CustomTableName.Player.Schema.TestData do
  use Yacto.Schema

  def dbname(), do: :player

  schema @auto_source do
    field(:name, :string, default: "hoge", meta: [null: false, size: 100])
  end
end

defmodule CustomTableName.Player.Unmatch.TestData do
  use Yacto.Schema

  def dbname(), do: :player

  schema @auto_source do
    field(:name, :string, default: "hoge", meta: [null: false, size: 100])
  end
end

