defmodule Yacto.DBTest do
  use PowerAssert

  @databases %{
    default: %{module: Yacto.DB.Single, repo: Yacto.Repo.Default},
    player: %{module: Yacto.DB.Shard, repos: [Yacto.Repo.Player1, Yacto.Repo.Player2]}
  }

  test "Yacto.DB.repo" do
    assert Yacto.Repo.Default == Yacto.DB.repo(:default, databases: @databases)

    assert Yacto.Repo.Player2 ==
             Yacto.DB.repo(:player, shard_key: "player_id1", databases: @databases)

    assert Yacto.Repo.Player1 ==
             Yacto.DB.repo(:player, shard_key: "player_id7", databases: @databases)
  end

  test "Yacto.DB.repos" do
    assert [Yacto.Repo.Default] == Yacto.DB.repos(:default, databases: @databases)

    assert [Yacto.Repo.Player1, Yacto.Repo.Player2] ==
             Yacto.DB.repos(:player, databases: @databases)
  end

  def hash(shard_key, num) do
    assert "player_id" == shard_key
    assert 2 == num
    0
  end

  test "With mfa" do
    databases = %{
      player: %{
        module: Yacto.DB.Shard,
        repos: [Yacto.Repo.Player1, Yacto.Repo.Player2],
        hash_mfa: {__MODULE__, :hash, []}
      }
    }

    assert Yacto.Repo.Player1 ==
             Yacto.DB.repo(:player, shard_key: "player_id", databases: databases)
  end
end
