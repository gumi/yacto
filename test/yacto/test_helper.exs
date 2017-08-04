Mix.Task.run "ecto.drop"
Mix.Task.run "ecto.create"

{:ok, _} = Yacto.XATest.Repo0.start_link()
{:ok, _} = Yacto.XATest.Repo1.start_link()

:ok = Ecto.Migrator.up(Yacto.XATest.Repo0, 20170408225025, Yacto.XATest.Player.Migration)
:ok = Ecto.Migrator.up(Yacto.XATest.Repo1, 20170408225025, Yacto.XATest.Player.Migration)

ExUnit.start()
