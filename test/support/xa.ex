defmodule Yacto.XATest.Repo0 do
  use Ecto.Repo, otp_app: :yacto, adapter: Ecto.Adapters.MySQL
end

defmodule Yacto.XATest.Repo1 do
  use Ecto.Repo, otp_app: :yacto, adapter: Ecto.Adapters.MySQL
end

defmodule Yacto.XATest.Player do
  use Ecto.Schema

  schema "xa_player" do
    field(:name)
    field(:value, :integer)
  end
end

defmodule Yacto.XATest.Player.Migration do
  use Ecto.Migration

  def change() do
    create table(:xa_player) do
      add(:name, :string, null: false)
      add(:value, :integer, null: false)
    end
  end
end
