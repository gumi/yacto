defmodule Yacto.QueryTest do
  use PowerAssert
  require Ecto.Query

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
      _ = repo.__adapter__().storage_down(config)
      :ok = repo.__adapter__().storage_up(config)
    end

    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.QueryTest.Repo.Default, default_config})
    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.QueryTest.Repo.Player0, player0_config})
    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.QueryTest.Repo.Player1, player1_config})

    # クエリのテストが出来ればいいだけなので、
    # ここでは Yacto の機能を使わずにマイグレートする
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

  @player_id "player_id"
  @databases %{
    default: %{module: Yacto.DB.Single, repo: Yacto.QueryTest.Repo.Default},
    player: %{
      module: Yacto.DB.Shard,
      repos: [Yacto.QueryTest.Repo.Player0, Yacto.QueryTest.Repo.Player1]
    }
  }

  setup do
    repo_default = Yacto.DB.repo(:default, databases: @databases)
    item = repo_default.insert!(%Yacto.QueryTest.Item{name: "foo", quantity: 100})

    repo_player = Yacto.DB.repo(:player, shard_key: @player_id, databases: @databases)
    player = repo_player.insert!(%Yacto.QueryTest.Player{name: "player", value: 1000})

    ExUnit.Callbacks.on_exit(fn -> cleanup() end)

    [item_id: item.id, player_id: player.id]
  end

  defp cleanup() do
    repo_default = Yacto.DB.repo(:default, databases: @databases)
    repo_player = Yacto.DB.repo(:player, shard_key: @player_id, databases: @databases)
    Yacto.QueryTest.Item |> Ecto.Query.where([], true) |> repo_default.delete_all()
    Yacto.QueryTest.Player |> Ecto.Query.where([], true) |> repo_player.delete_all()
  end

  test "Yacto.Query.get_for_update", context do
    repo = Yacto.DB.repo(Yacto.QueryTest.Item.dbname(), databases: @databases)
    obj = repo.get_for_update!(Yacto.QueryTest.Item, context[:item_id])

    assert obj.id == context[:item_id]
    assert obj.name == "foo"
    assert obj.quantity == 100

    repo =
      Yacto.DB.repo(Yacto.QueryTest.Player.dbname(), shard_key: @player_id, databases: @databases)

    obj = repo.get_for_update!(Yacto.QueryTest.Player, context[:player_id])

    assert obj.id == context[:player_id]
    assert obj.name == "player"
    assert obj.value == 1000
  end

  test "Yacto.Query.get_by_for_update" do
    repo = Yacto.DB.repo(Yacto.QueryTest.Item.dbname(), databases: @databases)
    obj = repo.get_by_for_update!(Yacto.QueryTest.Item, name: "foo")

    assert obj.name == "foo"
    assert obj.quantity == 100

    repo =
      Yacto.DB.repo(Yacto.QueryTest.Player.dbname(), shard_key: @player_id, databases: @databases)

    obj = repo.get_by_for_update!(Yacto.QueryTest.Player, name: "player")

    assert obj.name == "player"
    assert obj.value == 1000
  end

  defp test_get_by_or_new(lock) do
    repo = Yacto.DB.repo(Yacto.QueryTest.Item.dbname(), databases: @databases)

    {obj, false} =
      if lock do
        repo.get_by_or_insert_for_update(
          Yacto.QueryTest.Item,
          [name: "foo"],
          Ecto.Changeset.change(%Yacto.QueryTest.Item{name: "foo", quantity: 1000})
        )
      else
        repo.get_by_or_new(Yacto.QueryTest.Item, [name: "foo"], %Yacto.QueryTest.Item{
          name: "foo",
          quantity: 1000
        })
      end

    assert obj.name == "foo"
    assert obj.quantity == 100

    {obj, true} =
      if lock do
        repo.get_by_or_insert_for_update(
          Yacto.QueryTest.Item,
          [name: "bar"],
          Ecto.Changeset.change(%Yacto.QueryTest.Item{name: "bar", quantity: 1000})
        )
      else
        repo.get_by_or_new(Yacto.QueryTest.Item, [name: "bar"], %Yacto.QueryTest.Item{
          name: "bar",
          quantity: 1000
        })
      end

    assert obj.name == "bar"
    assert obj.quantity == 1000

    repo =
      Yacto.DB.repo(Yacto.QueryTest.Player.dbname(), shard_key: @player_id, databases: @databases)

    {obj, false} =
      if lock do
        repo.get_by_or_insert_for_update(
          Yacto.QueryTest.Player,
          [name: "player"],
          Ecto.Changeset.change(%Yacto.QueryTest.Player{name: "player", value: 999})
        )
      else
        repo.get_by_or_new(Yacto.QueryTest.Player, [name: "player"], %Yacto.QueryTest.Player{
          name: "player",
          value: 999
        })
      end

    assert obj.name == "player"
    assert obj.value == 1000
    assert obj.updated_at != nil
    assert obj.inserted_at != nil

    {obj, true} =
      if lock do
        repo.get_by_or_insert_for_update(
          Yacto.QueryTest.Player,
          [name: "not player"],
          Ecto.Changeset.change(%Yacto.QueryTest.Player{name: "not player", value: 999})
        )
      else
        repo.get_by_or_new(Yacto.QueryTest.Player, [name: "not player"], %Yacto.QueryTest.Player{
          name: "not player",
          value: 999
        })
      end

    assert obj.name == "not player"
    assert obj.value == 999

    if lock do
      assert obj.updated_at != nil
      assert obj.inserted_at != nil
    else
      assert obj.updated_at == nil
      assert obj.inserted_at == nil
    end
  end

  test "Yacto.Repo.get_by_or_new with no lock" do
    test_get_by_or_new(false)
  end

  test "Yacto.Repo.get_by_or_new with lock" do
    test_get_by_or_new(true)
  end

  test "Yacto.Repo.find" do
    mod = Yacto.QueryTest.Item
    repo = Yacto.DB.repo(mod.dbname(), databases: @databases)
    assert length(repo.find(mod, name: "foo")) == 1
    assert length(repo.find(mod, name: "bar")) == 0
    mod = Yacto.QueryTest.Player
    repo = Yacto.DB.repo(mod.dbname(), shard_key: @player_id, databases: @databases)
    assert length(repo.find(mod, name: "player")) == 1
    assert length(repo.find(mod, name: "not player")) == 0
  end

  test "Yacto.Repo.count" do
    mod = Yacto.QueryTest.Item
    repo = Yacto.DB.repo(mod.dbname(), databases: @databases)
    assert repo.count(mod, name: "foo") == 1
    assert repo.count(mod, name: "bar") == 0
    mod = Yacto.QueryTest.Player
    repo = Yacto.DB.repo(mod.dbname(), shard_key: @player_id, databases: @databases)
    assert repo.count(mod, name: "player") == 1
    assert repo.count(mod, name: "not player") == 0
  end

  test "Yacto.Repo.delete_by" do
    mod = Yacto.QueryTest.Player
    repo = Yacto.DB.repo(mod.dbname(), shard_key: @player_id, databases: @databases)
    assert repo.delete_by(mod, name: "player") == {1, nil}
    assert repo.delete_by(mod, name: "player") == {0, nil}

    assert_raise Ecto.NoResultsError, fn ->
      repo.delete_by!(mod, name: "player")
    end
  end
end
