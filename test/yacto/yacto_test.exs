defmodule YactoTest do
  use PowerAssert

  @databases %{
    default: %{module: Yacto.DB.Single, repo: Yacto.QueryTest.Repo.Default},
    player: %{
      module: Yacto.DB.Shard,
      repos: [Yacto.QueryTest.Repo.Player0, Yacto.QueryTest.Repo.Player1]
    }
  }

  setup_all do
    default_config = [
      database: "yacto_query_repo_default",
      username: "root",
      password: "",
      hostname: "localhost",
      port: 3306
    ]

    player0_config = [
      database: "yacto_query_repo_player0",
      username: "root",
      password: "",
      hostname: "localhost",
      port: 3306
    ]

    player1_config = [
      database: "yacto_query_repo_player1",
      username: "root",
      password: "",
      hostname: "localhost",
      port: 3306
    ]

    for {repo, config} <- [
          {Yacto.QueryTest.Repo.Default, default_config},
          {Yacto.QueryTest.Repo.Player0, player0_config},
          {Yacto.QueryTest.Repo.Player1, player1_config}
        ] do
      _ = repo.__adapter__.storage_down(config)
      :ok = repo.__adapter__.storage_up(config)
    end

    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.QueryTest.Repo.Default, default_config})
    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.QueryTest.Repo.Player0, player0_config})
    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.QueryTest.Repo.Player1, player1_config})

    :ok =
      Ecto.Migrator.up(
        Yacto.QueryTest.Repo.Default,
        20_170_408_225_025,
        Yacto.QueryTest.Default.Migration
      )

    :ok =
      Ecto.Migrator.up(
        Yacto.QueryTest.Repo.Player0,
        20_170_408_225_025,
        Yacto.QueryTest.Player.Migration
      )

    :ok =
      Ecto.Migrator.up(
        Yacto.QueryTest.Repo.Player1,
        20_170_408_225_025,
        Yacto.QueryTest.Player.Migration
      )

    :ok
  end

  test "Yacto.transaction" do
    result =
      Yacto.transaction(
        [:default, {:player, "player_id1"}, {:player, "player_id2"}],
        fn ->
          :ok
        end,
        databases: @databases
      )

    assert :ok = result
  end
end
