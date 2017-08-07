defmodule Yacto.DBTest do
  use PowerAssert

  setup do
    databases = %{default: %{module: Yacto.DB.Single,
                             repo: Yacto.Repo.Default},
                  player: %{module: Yacto.DB.Shard,
                            repos: [Yacto.Repo.Player1,
                                    Yacto.Repo.Player2]}}
    Application.put_env(:yacto, :databases, databases)
    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :databases) end)
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
end
