defmodule Yacto.DBTest do
  use PowerAssert

  setup do
    Memoize.invalidate()

    old_databases = Application.fetch_env!(:yacto, :databases)

    ExUnit.Callbacks.on_exit(fn ->
      Application.put_env(:yacto, :databases, old_databases)
      Memoize.invalidate()
    end)

    databases = %{
      default: %{module: Yacto.DB.Single, repo: Yacto.Repo.Default},
      player: %{module: Yacto.DB.Shard, repos: [Yacto.Repo.Player1, Yacto.Repo.Player2]}
    }

    Application.put_env(:yacto, :databases, databases)

    :ok
  end

  test "Yacto.DB.repo" do
    assert Yacto.Repo.Default == Yacto.DB.repo(:default, nil)
    assert Yacto.Repo.Player2 == Yacto.DB.repo(:player, "player_id1")
    assert Yacto.Repo.Player1 == Yacto.DB.repo(:player, "player_id7")
  end

  test "Yacto.DB.repos" do
    assert [Yacto.Repo.Default] == Yacto.DB.repos(:default)
    assert [Yacto.Repo.Player1, Yacto.Repo.Player2] == Yacto.DB.repos(:player)
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

    Application.put_env(:yacto, :databases, databases)

    assert Yacto.Repo.Player1 == Yacto.DB.repo(:player, "player_id")
  end
end
