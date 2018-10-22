defmodule Yacto.QueryTest.Repo.Default do
  use Ecto.Repo, otp_app: :yacto, adapter: Ecto.Adapters.MySQL
  use Yacto.Repo.Helper
end

defmodule Yacto.QueryTest.Repo.Player0 do
  use Ecto.Repo, otp_app: :yacto, adapter: Ecto.Adapters.MySQL
  use Yacto.Repo.Helper
end

defmodule Yacto.QueryTest.Repo.Player1 do
  use Ecto.Repo, otp_app: :yacto, adapter: Ecto.Adapters.MySQL
  use Yacto.Repo.Helper
end

defmodule Yacto.QueryTest.Item do
  use Yacto.Schema.Single, dbname: :default

  schema "item" do
    field(:name, :string)
    field(:quantity, :integer)
  end
end

defmodule Yacto.QueryTest.Default.Migration do
  use Ecto.Migration

  def change() do
    create table(:item) do
      add(:name, :string, null: false)
      add(:quantity, :integer, null: false)
    end
  end
end

defmodule Yacto.QueryTest.Player do
  use Yacto.Schema.Shard, dbname: :player

  schema "xa_player" do
    field(:name)
    field(:value, :integer)
    timestamps()
  end
end

defmodule Yacto.QueryTest.Player.Migration do
  use Ecto.Migration

  def change() do
    create table(:xa_player, primary_key: false) do
      add(:id, :serial, primary_key: true)
      add(:name, :string, null: false)
      add(:value, :integer, null: false)
      timestamps()
    end
  end
end
