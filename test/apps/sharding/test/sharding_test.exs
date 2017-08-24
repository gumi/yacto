defmodule ShardingTest do
  use ExUnit.Case

  test "config" do
    assert [otp_app: :sharding,
            repo: Sharding.Repo.Player0,
            timeout: 15000,
            pool_timeout: 5000,
            adapter: Ecto.Adapters.MySQL,
            database: "sharding_repo_player0",
            username: "root",
            password: "",
            hostname: "localhost",
            port: "3306"] == Sharding.Repo.Player0.config()
    assert [otp_app: :sharding,
            repo: Sharding.Repo.Player1,
            timeout: 15000,
            pool_timeout: 5000,
            adapter: Ecto.Adapters.MySQL,
            database: "sharding_repo_player1",
            username: "root",
            password: "",
            hostname: "localhost",
            port: "3306"] == Sharding.Repo.Player1.config()
    assert [otp_app: :sharding,
            repo: Sharding.Repo.Default,
            timeout: 15000,
            pool_timeout: 5000,
            adapter: Ecto.Adapters.MySQL,
            database: "sharding_default",
            username: "root",
            password: "",
            hostname: "localhost",
            port: "3306"] == Sharding.Repo.Default.config()
  end

  test "shard" do
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "1")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "2")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "3")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "4")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "5")
    assert Sharding.Repo.Player0 == Yacto.DB.repo(:player, "6")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "7")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "8")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "9")
    assert Sharding.Repo.Player0 == Yacto.DB.repo(:player, "01")
    assert Sharding.Repo.Player0 == Yacto.DB.repo(:player, "02")
    assert Sharding.Repo.Player0 == Yacto.DB.repo(:player, "03")
    assert Sharding.Repo.Player0 == Yacto.DB.repo(:player, "04")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "05")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "06")
    assert Sharding.Repo.Player0 == Yacto.DB.repo(:player, "07")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "08")
    assert Sharding.Repo.Player1 == Yacto.DB.repo(:player, "09")
  end
end
