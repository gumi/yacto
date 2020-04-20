defmodule Yacto.MigratorTest.Player do
  use Yacto.Schema

  def dbname(), do: :player

  schema "player" do
    field(:name)
    field(:value, :integer)
    timestamps()
  end
end

defmodule Yacto.MigratorTest.Player2 do
  use Yacto.Schema

  def dbname(), do: :player

  schema "player2" do
    field(:name2)
    field(:value, :string)
  end
end

defmodule Yacto.MigratorTest.Player3 do
  use Yacto.Schema

  def dbname(), do: :player

  schema @auto_source do
    field(:name3, :string, default: "hage", meta: [null: false, size: 100])
    field(:value, :string)
    field(:text, :string, source: :text_data, meta: [type: :text, null: false])
    index([:value, :name3])
    index([:name3, :value], unique: true)
  end
end

defmodule Yacto.MigratorTest.Item do
  use Yacto.Schema

  def dbname(), do: :default

  @primary_key {:id, :binary_id, autogenerate: true}

  schema @auto_source do
    field(:name, :string, meta: [null: false])
  end
end

defmodule Yacto.MigratorTest.UnsignedBigInteger do
  use Yacto.Schema

  @impl Yacto.Schema
  def dbname(), do: :default

  schema @auto_source do
    field(:user_id, :integer, meta: [null: false, type: :"bigint(20) unsigned"])
  end
end

defmodule Yacto.MigratorTest.CustomPrimaryKey do
  use Yacto.Schema

  def primary_key() do
    String.duplicate("a", 10)
  end

  def dbname(), do: :default

  @primary_key {:id, :string, autogenerate: {__MODULE__, :primary_key, []}}
  @primary_key_meta %{id: [size: 10]}

  schema @auto_source do
    field(:name, :string, meta: [null: false])
  end
end

defmodule Yacto.MigratorTest.CoinType do
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

defmodule Yacto.MigratorTest.Coin do
  use Yacto.Schema

  @impl Yacto.Schema
  def dbname(), do: :default

  schema @auto_source do
    field(:type, Yacto.MigratorTest.CoinType, default: :common_coin, meta: [null: false])
  end
end

defmodule Yacto.MigratorTest.DropFieldWithIndex do
  use Yacto.Schema, dbname: :default

  schema @auto_source do
    field(:value1, :string, meta: [null: false, index: true])
    field(:value2, :string, meta: [null: false])
  end
end

defmodule Yacto.MigratorTest.DropFieldWithIndex2 do
  use Yacto.Schema, as: Yacto.MigratorTest.DropFieldWithIndex, dbname: :default

  schema @auto_source do
    field(:value2, :string, meta: [null: false, index: true])
  end
end

defmodule Yacto.MigratorTest.Repo0 do
  use Ecto.Repo, otp_app: :migrator, adapter: Ecto.Adapters.MyXQL
end

defmodule Yacto.MigratorTest.Repo1 do
  use Ecto.Repo, otp_app: :migrator, adapter: Ecto.Adapters.MyXQL
end
