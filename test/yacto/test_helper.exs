Mix.Task.run("ecto.drop")
Mix.Task.run("ecto.create")

{:ok, _} = Yacto.XATest.Repo0.start_link()
{:ok, _} = Yacto.XATest.Repo1.start_link()

:ok = Ecto.Migrator.up(Yacto.XATest.Repo0, 20_170_408_225_025, Yacto.XATest.Player.Migration)
:ok = Ecto.Migrator.up(Yacto.XATest.Repo1, 20_170_408_225_025, Yacto.XATest.Player.Migration)

{:ok, _} = Yacto.QueryTest.Repo.Default.start_link()
{:ok, _} = Yacto.QueryTest.Repo.Player0.start_link()
{:ok, _} = Yacto.QueryTest.Repo.Player1.start_link()

:ok =
  Ecto.Migrator.up(
    Yacto.QueryTest.Repo.Default,
    20_170_408_225_025,
    Yacto.QueryTest.Default.Migration
  )

:ok =
  Ecto.Migrator.up(
    Yacto.QueryTest.Repo.Player0,
    20_170_408_225_025,
    Yacto.QueryTest.Player.Migration
  )

:ok =
  Ecto.Migrator.up(
    Yacto.QueryTest.Repo.Player1,
    20_170_408_225_025,
    Yacto.QueryTest.Player.Migration
  )

ExUnit.start()
