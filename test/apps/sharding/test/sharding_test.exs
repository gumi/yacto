defmodule ShardingTest do
  use ExUnit.Case

  test "config" do
    assert [
             telemetry_prefix: [:sharding, :repo, :player0],
             otp_app: :sharding,
             timeout: 15000,
             pool_size: 10,
             database: "sharding_repo_player0",
             username: "root",
             password: "",
             hostname: "localhost",
             port: "3306"
           ] == Sharding.Repo.Player0.config()

    assert [
             telemetry_prefix: [:sharding, :repo, :player1],
             otp_app: :sharding,
             timeout: 15000,
             pool_size: 10,
             database: "sharding_repo_player1",
             username: "root",
             password: "",
             hostname: "localhost",
             port: "3306"
           ] == Sharding.Repo.Player1.config()

    assert [
             telemetry_prefix: [:sharding, :repo, :default],
             otp_app: :sharding,
             timeout: 15000,
             pool_size: 10,
             database: "sharding_default",
             username: "root",
             password: "",
             hostname: "localhost",
             port: "3306"
           ] == Sharding.Repo.Default.config()
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
