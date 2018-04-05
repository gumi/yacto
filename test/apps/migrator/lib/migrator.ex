defmodule Migrator.Player do
  use Yacto.Schema

  def dbname(), do: :player

  schema "player" do
    field(:name)
    field(:value, :integer)
    timestamps()
  end
end

defmodule Migrator.Player2 do
  use Yacto.Schema

  def dbname(), do: :player

  schema "player2" do
    field(:name2)
    field(:value, :string)
  end
end

defmodule Migrator.Player3 do
  use Yacto.Schema

  def dbname(), do: :player

  schema @auto_source do
    field(:name3, :string, default: "hage", meta: [null: false, size: 100])
    field(:value, :string)
    field(:text, :string, meta: [type: :text, null: false])
    index([:value, :name3])
    index([:name3, :value], unique: true)
  end
end

defmodule Migrator.Item do
  use Yacto.Schema

  def dbname(), do: :default

  @primary_key {:id, :binary_id, autogenerate: true}

  schema @auto_source do
    field(:name, :string, meta: [null: false])
  end
end

defmodule Migrator.UnsignedBigInteger do
  use Yacto.Schema

  @impl Yacto.Schema
  def dbname(), do: :default

  schema @auto_source do
    field(:user_id, :integer, meta: [null: false, type: :"bigint(20) unsigned"])
  end
end

defmodule Migrator.Repo0 do
  use Ecto.Repo, otp_app: :migrator
end

defmodule Migrator.Repo1 do
  use Ecto.Repo, otp_app: :migrator
end
