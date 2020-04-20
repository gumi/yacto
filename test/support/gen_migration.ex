defmodule Yacto.GenMigrationTest.Player do
  use Yacto.Schema, dbname: :player

  schema "player" do
    field(:name)
    field(:value, :integer)
    timestamps()
  end
end

defmodule Yacto.GenMigrationTest.Player2 do
  use Yacto.Schema, as: Yacto.GenMigrationTest.Player, dbname: :player

  schema "player2" do
    field(:name2)
    field(:value, :string)
  end
end

defmodule Yacto.GenMigrationTest.Player3 do
  use Yacto.Schema, as: Yacto.GenMigrationTest.Player, dbname: :player

  schema @auto_source do
    field(:name3, :string, meta: [null: false, size: 100])
    field(:value, :string)
    index([:value, :name3])
    index([:name3, :value], unique: true)
  end
end

defmodule Yacto.GenMigrationTest.Item do
  use Yacto.Schema, dbname: :default

  @primary_key {:id, :binary_id, autogenerate: true}

  schema @auto_source do
    field(:name)
  end
end

defmodule Yacto.GenMigrationTest.CoinType do
  @behaviour Ecto.Type

  @impl Ecto.Type
  def type(), do: :integer

  @impl Ecto.Type
  def cast(:free_coin), do: {:ok, :free_coin}
  def cast(:paid_coin), do: {:ok, :paid_coin}
  def cast(:common_coin), do: {:ok, :common_coin}
  def cast(_), do: :error

  @impl Ecto.Type
  def load(0), do: {:ok, :free_coin}
  def load(1), do: {:ok, :paid_coin}
  def load(2), do: {:ok, :common_coin}
  def load(_), do: :error

  @impl Ecto.Type
  def dump(:free_coin), do: {:ok, 0}
  def dump(:paid_coin), do: {:ok, 1}
  def dump(:common_coin), do: {:ok, 2}
  def dump(_), do: :error
end

defmodule Yacto.GenMigrationTest.Coin do
  use Yacto.Schema, dbname: :player

  schema @auto_source do
    field(:player_id, :string, meta: [null: false])
    field(:type_id, Yacto.GenMigrationTest.CoinType, meta: [null: false])
    field(:platform, :string, meta: [length: 64, null: false])
    field(:quantity, :integer, default: 0, meta: [null: false])
    field(:description, :string, meta: [type: :text, null: false])
    timestamps()

    index([:player_id, :type_id, :platform], unique: true)
  end
end

defmodule Yacto.GenMigrationTest.ManyIndex do
  use Yacto.Schema, dbname: :default

  schema @auto_source do
    field(:aaaaaa, :string)
    field(:bbbbbb, :string)
    field(:cccccc, :string)
    field(:dddddd, :string)

    index([:aaaaaa, :bbbbbb, :cccccc, :dddddd])
  end
end

defmodule Yacto.GenMigrationTest.DecimalOption do
  use Yacto.Schema, dbname: :player

  schema @auto_source do
    field(:player_id, :string)
    field(:decimal_field, :decimal, meta: [precision: 7, scale: 3])
    field(:name, :string, meta: [null: true])
  end
end

defmodule Yacto.GenMigrationTest.Repo0 do
  use Ecto.Repo, otp_app: :migrator, adapter: Ecto.Adapters.MyXQL
end
