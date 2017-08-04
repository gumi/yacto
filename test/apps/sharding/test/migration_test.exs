defmodule Sharding.MigrationTest do
  use ExUnit.Case
  require Ecto.Query

  test "migration" do
    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir(:sharding))
    Mix.Task.rerun "ecto.drop"
    Mix.Task.rerun "ecto.create"
    Mix.Task.rerun "yacto.gen.migration", ["--app", "sharding"]
    Mix.Task.rerun "yacto.migrate", ["--app", "sharding", "--repo", "Sharding.Repo.Default"]
    Mix.Task.rerun "yacto.migrate", ["--app", "sharding", "--repo", "Sharding.Repo.Player0"]
    Mix.Task.rerun "yacto.migrate", ["--app", "sharding", "--repo", "Sharding.Repo.Player1"]

    item = %Sharding.Schema.Item{name: "item"}
    item = Sharding.Repo.Default.insert!(item)
    assert [item] == Sharding.Schema.Item |> Ecto.Query.where(name: "item") |> Sharding.Repo.Default.all()

    player = %Sharding.Schema.Player{name: "player"}
    player = Sharding.Repo.Player.shard("key").insert!(player)
    assert [player] == Sharding.Schema.Player |> Ecto.Query.where(name: "player") |> Sharding.Repo.Player.shard("key").all()
  end
end
