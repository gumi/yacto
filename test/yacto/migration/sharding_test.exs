defmodule Yacto.Migration.ShardingTest do
  use ExUnit.Case

  @databases %{
    default: %{module: Yacto.DB.Single, repo: Yacto.ShardingTest.Repo.Default},
    player: %{
      module: Yacto.DB.Shard,
      repos: [Yacto.ShardingTest.Repo.Player0, Yacto.ShardingTest.Repo.Player1]
    }
  }

  test "shard" do
    # 短くする
    repo = fn shard_key ->
      Yacto.DB.repo(:player, shard_key: shard_key, databases: @databases)
    end

    assert Yacto.ShardingTest.Repo.Player1 == repo.("1")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("2")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("3")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("4")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("5")
    assert Yacto.ShardingTest.Repo.Player0 == repo.("6")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("7")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("8")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("9")
    assert Yacto.ShardingTest.Repo.Player0 == repo.("01")
    assert Yacto.ShardingTest.Repo.Player0 == repo.("02")
    assert Yacto.ShardingTest.Repo.Player0 == repo.("03")
    assert Yacto.ShardingTest.Repo.Player0 == repo.("04")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("05")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("06")
    assert Yacto.ShardingTest.Repo.Player0 == repo.("07")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("08")
    assert Yacto.ShardingTest.Repo.Player1 == repo.("09")
  end
end
