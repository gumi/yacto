defmodule CustomTableName.Player.Schema.TestData do
  use Yacto.Schema

  def dbname(), do: :player

  schema @auto_source do
    field(:name, :string, default: "hage", meta: [null: false, size: 100])
    field(:value, :string)
    field(:text, :string, source: :text_data, meta: [type: :text, null: false])
    index([:value, :name])
    index([:name, :value], unique: true)
  end
end

defmodule CustomTableName.Item do
  use Yacto.Schema

  def dbname(), do: :default

  @primary_key {:id, :binary_id, autogenerate: true}

  schema @auto_source do
    field(:name, :string, meta: [null: false])
  end
end

