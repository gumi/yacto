defmodule Yacto.ShardingTest.Repo.Default do
  use Ecto.Repo, otp_app: :yacto, adapter: Ecto.Adapters.MyXQL
end

for n <- 0..1 do
  defmodule Module.concat(Yacto.ShardingTest.Repo, "Player#{n}") do
    use Ecto.Repo, otp_app: :yacto, adapter: Ecto.Adapters.MyXQL
  end
end

defmodule Yacto.ShardingTest.Schema.Item do
  use Yacto.Schema

  def dbname(), do: :default

  schema @auto_source do
    field(:name, :string)
  end
end

defmodule Yacto.ShardingTest.Schema.Player do
  use Yacto.Schema

  def dbname(), do: :player

  schema @auto_source do
    field(:name, :string)
  end
end
