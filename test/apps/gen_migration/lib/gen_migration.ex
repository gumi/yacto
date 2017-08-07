defmodule GenMigration.Player do
  use Ecto.Schema

  schema "player" do
    field :name
    field :value, :integer
    timestamps()
  end
end

defmodule GenMigration.Player2 do
  use Ecto.Schema

  schema "player2" do
    field :name2
    field :value, :string
  end
end

defmodule GenMigration.Player3 do
  use Yacto.Schema

  @impl Yacto.Schema
  def dbname(), do: :player

  schema @auto_source do
    field :name3, :string, meta: [null: false, size: 100]
    field :value, :string
    index [:value, :name3]
    index [:name3, :value], unique: true
  end
end

defmodule GenMigration.Item do
  use Yacto.Schema

  @impl Yacto.Schema
  def dbname(), do: :default

  @primary_key {:id, :binary_id, autogenerate: true}

  schema @auto_source do
    field :name
  end
end

