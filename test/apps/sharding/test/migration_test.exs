defmodule Sharding.MigrationTest do
  use ExUnit.Case
  require Ecto.Query

  test "migration" do
    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir(:sharding))
    Mix.Task.rerun "ecto.drop"
    Mix.Task.rerun "ecto.create"
    Mix.Task.rerun "yacto.gen.migration", ["--app", "sharding"]
    Mix.Task.rerun "yacto.migrate", ["--app", "sharding"]

    item = %Sharding.Schema.Item{name: "item"}
    item = Yacto.DB.repo(:default).insert!(item)
    assert [item] == Sharding.Schema.Item |> Ecto.Query.where(name: "item") |> Yacto.DB.repo(:default).all()

    player = %Sharding.Schema.Player{name: "player"}
    player = Yacto.DB.repo(:player, "key").insert!(player)
    assert [player] == Sharding.Schema.Player |> Ecto.Query.where(name: "player") |> Yacto.DB.repo(:player, "key").all()
  end
end
