defmodule Yacto.Migration.MigrationTest do
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

    for {repo, config} <- [default_config] ++ player_configs do
      _ = repo.__adapter__.storage_down(config)
      :ok = repo.__adapter__.storage_up(config)
    end

    {:ok, _} = ExUnit.Callbacks.start_supervised(default_config)

    for config <- player_configs do
      {:ok, _} = ExUnit.Callbacks.start_supervised(config)
    end

    Application.put_env(:yacto, :databases, @databases)
    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :databases) end)
  end

  test "migration" do
    dir = Yacto.Migration.Util.get_migration_dir_for_gen()
    _ = File.rm_rf(dir)

    Mix.Task.rerun("yacto.gen.migration", [
      "--prefix",
      "Yacto.ShardingTest",
      "--migration-dir",
      dir
    ])

    Mix.Task.rerun("yacto.migrate", ["--migration-dir", dir])

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
