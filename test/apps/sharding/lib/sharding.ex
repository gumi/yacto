
defmodule Sharding.Repo.Default do
  use Ecto.Repo, otp_app: :sharding
end

for n <- 0..1 do
  defmodule Module.concat(Sharding.Repo, "Player#{n}") do
    use Ecto.Repo, otp_app: :sharding
  end
end

defmodule Sharding.Repo.Player do
  use Yacto.Shard.Repo, repos: for n <- 0..1, do: Module.concat(Sharding.Repo, "Player#{n}")
end

defmodule Sharding.Schema.Item do
  use Yacto.Migration.Schema

  schema @auto_source do
    field :name, :string
  end
end

defmodule Sharding.Schema.Player do
  use Yacto.Shard.Schema, shard_repo: Sharding.Repo.Player

  schema @auto_source do
    field :name, :string
  end
end

defmodule Sharding do
end
