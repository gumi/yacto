defmodule Migrator.Player do
  use Ecto.Schema

  schema "player" do
    field :name
    field :value, :integer
    timestamps()
  end
end

defmodule Migrator.Player2 do
  use Ecto.Schema

  schema "player2" do
    field :name2
    field :value, :string
  end
end

defmodule Migrator.Player3 do
  use Yacto.Schema

  schema @auto_source do
    field :name3, :string, meta: [null: false, size: 100]
    field :value, :string
    index [:value, :name3]
    index [:name3, :value], unique: true
  end
end

defmodule Migrator.Item do
  use Yacto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema @auto_source do
    field :name, :string, meta: [null: false]
  end
end

defmodule Migrator.Repo0 do
  use Ecto.Repo, otp_app: :migrator
end
defmodule Migrator.Repo1 do
  use Ecto.Repo, otp_app: :migrator
end

defmodule Migrator.Router1 do
  @behaviour Yacto.Migration.Router

  def allow_migrate(Migrator.Player, Migrator.Repo0, _opts) do
    true
  end

  def allow_migrate(_schema, _repo, _opts) do
    nil
  end
end

defmodule Migrator.Router2 do
  @behaviour Yacto.Migration.Router

  def allow_migrate(Migrator.Player2, Migrator.Repo1, _opts) do
    true
  end

  def allow_migrate(Migrator.Item, Migrator.Repo1, _opts) do
    true
  end

  def allow_migrate(_schema, _repo, _opts) do
    false
  end
end

defmodule Migrator.MigrationRouters do
  use Yacto.Migration.Routers, otp_app: :migrator
end
