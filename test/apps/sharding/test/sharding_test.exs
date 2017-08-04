defmodule ShardingTest do
  use ExUnit.Case

  test "config" do
    assert [otp_app: :sharding,
            repo: Sharding.Repo.Player0,
            adapter: Ecto.Adapters.MySQL,
            database: "sharding_repo_player0",
            username: "root",
            password: "",
            hostname: "localhost",
            port: "3306"] == Sharding.Repo.Player0.config()
    assert [otp_app: :sharding,
            repo: Sharding.Repo.Player1,
            adapter: Ecto.Adapters.MySQL,
            database: "sharding_repo_player1",
            username: "root",
            password: "",
            hostname: "localhost",
            port: "3306"] == Sharding.Repo.Player1.config()
    assert [otp_app: :sharding,
            repo: Sharding.Repo.Default,
            adapter: Ecto.Adapters.MySQL,
            database: "sharding_default",
            username: "root",
            password: "",
            hostname: "localhost",
            port: "3306"] == Sharding.Repo.Default.config()
  end

  test "shard" do
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("1")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("2")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("3")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("4")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("5")
    assert Sharding.Repo.Player0 == Sharding.Repo.Player.shard("6")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("7")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("8")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("9")
    assert Sharding.Repo.Player0 == Sharding.Repo.Player.shard("01")
    assert Sharding.Repo.Player0 == Sharding.Repo.Player.shard("02")
    assert Sharding.Repo.Player0 == Sharding.Repo.Player.shard("03")
    assert Sharding.Repo.Player0 == Sharding.Repo.Player.shard("04")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("05")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("06")
    assert Sharding.Repo.Player0 == Sharding.Repo.Player.shard("07")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("08")
    assert Sharding.Repo.Player1 == Sharding.Repo.Player.shard("09")
  end
end
