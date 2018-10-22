defmodule MigrationRouter.Item do
  use Yacto.Schema

  def dbname(), do: :default

  schema "item" do
  end
end

defmodule MigrationRouter.Player do
  use Yacto.Schema

  def dbname(), do: :player

  schema "player" do
  end
end

defmodule MigrationRouter.Repo.Default do
  use Ecto.Repo, otp_app: :migration_router, adapter: Ecto.Adapters.MySQL
end

defmodule MigrationRouter.Repo.Player1 do
  use Ecto.Repo, otp_app: :migration_router, adapter: Ecto.Adapters.MySQL
end

defmodule MigrationRouter.Repo.Player2 do
  use Ecto.Repo, otp_app: :migration_router, adapter: Ecto.Adapters.MySQL
end
