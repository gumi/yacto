defmodule Yacto.QueryTest.Repo.Default do
  use Ecto.Repo, otp_app: :yacto
end

defmodule Yacto.QueryTest.Repo.Player0 do
  use Ecto.Repo, otp_app: :yacto
end

defmodule Yacto.QueryTest.Repo.Player1 do
  use Ecto.Repo, otp_app: :yacto
end

defmodule Yacto.QueryTest.Item do
  use Yacto.Schema

  def dbname(), do: :default

  schema "item" do
    field :name, :string
    field :quantity, :integer
  end
end

defmodule Yacto.QueryTest.Default.Migration do
  use Ecto.Migration

  def change() do
    create table(:item) do
      add :name, :string, null: false
      add :quantity, :integer, null: false
    end
  end
end

defmodule Yacto.QueryTest.Player do
  use Yacto.Schema

  def dbname(), do: :player

  schema "xa_player" do
    field :name
    field :value, :integer
    timestamps()
  end
end

defmodule Yacto.QueryTest.Player.Migration do
  use Ecto.Migration

  def change() do
    create table(:xa_player) do
      add :name, :string, null: false
      add :value, :integer, null: false
      timestamps()
    end
  end
end
