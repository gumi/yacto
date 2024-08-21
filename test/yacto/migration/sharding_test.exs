defmodule Yacto.Migration.ShardingTest do
  use ExUnit.Case

  require Ecto.Query

  @databases %{
    default: %{module: Yacto.DB.Single, repo: Yacto.ShardingTest.Repo.Default},
    player: %{
      module: Yacto.DB.Shard,
      repos: [Yacto.ShardingTest.Repo.Player0, Yacto.ShardingTest.Repo.Player1]
    }
  }

  setup do
    default_config =
      {Yacto.ShardingTest.Repo.Default,
       [
         database: "yacto_sharding_default",
         username: "root",
         password: "",
         hostname: "localhost",
         port: 3306
       ]}

    player_configs =
      for n <- 0..1 do
        {Module.concat(Yacto.ShardingTest.Repo, "Player#{n}"),
         [
           database: "yacto_sharding_player#{n}",
           username: "root",
           password: "",
           hostname: "localhost",
           port: 3306
         ]}
      end

    {:ok, _} = ExUnit.Callbacks.start_supervised(default_config)

    for config <- player_configs do
      {:ok, _} = ExUnit.Callbacks.start_supervised(config)
    end

    for {repo, config} <- [default_config] ++ player_configs do
      _ = repo.__adapter__().storage_down(config)
      :ok = repo.__adapter__().storage_up(config)
    end

    Application.put_env(:yacto, :databases, @databases)

    Application.put_env(:yacto, :ecto_repos, [
      Yacto.ShardingTest.Repo.Default,
      Yacto.ShardingTest.Repo.Player0,
      Yacto.ShardingTest.Repo.Player1
    ])

    ExUnit.Callbacks.on_exit(fn ->
      Application.delete_env(:yacto, :databases)
      Application.delete_env(:yacto, :ecto_repos)
    end)
  end

  test "repo がシャーディングされているか確認する" do
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

  test "yacto.gen.migration と yacto.migrate を試す" do
    migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()
    _ = File.rm_rf(migration_dir)

    Mix.Task.rerun("yacto.gen.migration", [
      "--prefix",
      "Yacto.ShardingTest",
      "--migration-dir",
      migration_dir
    ])

    Mix.Task.rerun("yacto.migrate", ["--migration-dir", migration_dir])

    item = %Yacto.ShardingTest.Schema.Item{name: "item"}
    item = Yacto.DB.repo(:default).insert!(item)

    assert [item] ==
             Yacto.ShardingTest.Schema.Item
             |> Ecto.Query.where(name: "item")
             |> Yacto.DB.repo(:default).all()

    player = %Yacto.ShardingTest.Schema.Player{name: "player"}
    player = Yacto.DB.repo(:player, shard_key: "key").insert!(player)

    assert [player] ==
             Yacto.ShardingTest.Schema.Player
             |> Ecto.Query.where(name: "player")
             |> Yacto.DB.repo(:player, shard_key: "key").all()
  end
end
