defmodule MigrationRouterTest do
  use PowerAssert

  test "Yacto.Migration.Router.allow_migrate" do
    assert true == MigrationRouter.Routers.allow_migrate(MigrationRouter.Player, MigrationRouter.Repo0, [])
    assert false == MigrationRouter.Routers.allow_migrate(MigrationRouter.Player, MigrationRouter.Repo1, [])
    assert false == MigrationRouter.Routers.allow_migrate(MigrationRouter.Player2, MigrationRouter.Repo0, [])
    assert true == MigrationRouter.Routers.allow_migrate(MigrationRouter.Player2, MigrationRouter.Repo1, [])
  end
end
