defmodule MigrationRouter.Player do
  use Ecto.Schema

  schema "player" do
    field :name
    field :value, :integer
    timestamps()
  end
end

defmodule MigrationRouter.Player2 do
  use Ecto.Schema

  schema "player2" do
    field :name2
    field :value, :string
  end
end

defmodule MigrationRouter.Repo0 do
  use Ecto.Repo, otp_app: :migration_router
end
defmodule MigrationRouter.Repo1 do
  use Ecto.Repo, otp_app: :migration_router
end

defmodule MigrationRouter.Router1 do
  @behaviour Yacto.Migration.Router

  def allow_migrate(MigrationRouter.Player, MigrationRouter.Repo0, _opts) do
    true
  end

  def allow_migrate(_schema, _repo, _opts) do
    nil
  end
end

defmodule MigrationRouter.Router2 do
  @behaviour Yacto.Migration.Router

  def allow_migrate(MigrationRouter.Player2, MigrationRouter.Repo1, _opts) do
    true
  end

  def allow_migrate(_schema, _repo, _opts) do
    false
  end
end

defmodule MigrationRouter.Routers do
  use Yacto.Migration.Routers, otp_app: :migration_router
end
