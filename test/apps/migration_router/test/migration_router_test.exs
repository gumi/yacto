defmodule MigrationRouterTest do
  use PowerAssert

  test "Yacto.Migration.Util.allow_migrate?" do
    assert true == Yacto.Migration.Util.allow_migrate?(MigrationRouter.Item, MigrationRouter.Repo.Default)
    assert false == Yacto.Migration.Util.allow_migrate?(MigrationRouter.Item, MigrationRouter.Repo.Player1)
    assert false == Yacto.Migration.Util.allow_migrate?(MigrationRouter.Item, MigrationRouter.Repo.Player2)
    assert false == Yacto.Migration.Util.allow_migrate?(MigrationRouter.Player, MigrationRouter.Repo.Default)
    assert true == Yacto.Migration.Util.allow_migrate?(MigrationRouter.Player, MigrationRouter.Repo.Player1)
    assert true == Yacto.Migration.Util.allow_migrate?(MigrationRouter.Player, MigrationRouter.Repo.Player2)
  end
end
