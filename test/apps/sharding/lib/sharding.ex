defmodule Sharding.Repo.Default do
  use Ecto.Repo, otp_app: :sharding, adapter: Ecto.Adapters.MySQL
end

for n <- 0..1 do
  defmodule Module.concat(Sharding.Repo, "Player#{n}") do
    use Ecto.Repo, otp_app: :sharding, adapter: Ecto.Adapters.MySQL
  end
end

defmodule Sharding.Schema.Item do
  use Yacto.Schema

  def dbname(), do: :default

  schema @auto_source do
    field(:name, :string)
  end
end

defmodule Sharding.Schema.Player do
  use Yacto.Schema

  def dbname(), do: :player

  schema @auto_source do
    field(:name, :string)
  end
end

defmodule Sharding do
end
