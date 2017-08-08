defmodule Yacto.QueryTest do
  use PowerAssert
  require Ecto.Query

  @player_id "player_id"

  setup do
    repo_default = Yacto.DB.repo(:default)
    item = repo_default.insert!(%Yacto.QueryTest.Item{name: "foo", quantity: 100})
    ExUnit.Callbacks.on_exit(fn -> repo_default.delete!(item) end)

    repo_player = Yacto.DB.repo(:player, @player_id)
    player = repo_player.insert!(%Yacto.QueryTest.Player{name: "player", value: 1000})
    ExUnit.Callbacks.on_exit(fn -> repo_player.delete!(player) end)

    :ok
  end

  test "Yacto.Query.get" do
    obj = Yacto.Query.get(Yacto.QueryTest.Item, Yacto.DB.repo(:default), lock: false, lookup: [name: "foo"])
    assert obj.name == "foo"
    assert obj.quantity == 100
    obj = Yacto.Query.get(Yacto.QueryTest.Item, Yacto.DB.repo(:default), lock: true, lookup: [quantity: 100])
    assert obj.name == "foo"
    assert obj.quantity == 100

    obj = Yacto.Query.get(Yacto.QueryTest.Player, Yacto.DB.repo(:player, @player_id), lock: false, lookup: [name: "player"])
    assert obj.name == "player"
    assert obj.value == 1000
  end

  test "Yacto.Schema.Query.get" do
    obj = Yacto.QueryTest.Item.Query.get(nil, lock: false, lookup: [name: "foo"])
    assert obj.name == "foo"
    assert obj.quantity == 100
    obj = Yacto.QueryTest.Item.Query.get(nil, lock: true, lookup: [quantity: 100])
    assert obj.name == "foo"
    assert obj.quantity == 100

    obj = Yacto.QueryTest.Player.Query.get(@player_id, lock: false, lookup: [name: "player"])
    assert obj.name == "player"
    assert obj.value == 1000
  end

  test "Yacto.Query.get_or_new" do
    {obj, false} = Yacto.Query.get_or_new(Yacto.QueryTest.Item, Yacto.DB.repo(:default), lookup: [name: "foo"], defaults: [quantity: 1000])
    assert obj.name == "foo"
    assert obj.quantity == 100
    {obj, true} = Yacto.Query.get_or_new(Yacto.QueryTest.Item, Yacto.DB.repo(:default), lookup: [name: "bar"], defaults: [quantity: 1000])
    assert obj.name == "bar"
    assert obj.quantity == 1000

    {obj, false} = Yacto.Query.get_or_new(Yacto.QueryTest.Player, Yacto.DB.repo(:player, @player_id), lookup: [name: "player"], defaults: [value: 999])
    assert obj.name == "player"
    assert obj.value == 1000
    assert obj.updated_at != nil
    assert obj.inserted_at != nil

    {obj, true} = Yacto.Query.get_or_new(Yacto.QueryTest.Player, Yacto.DB.repo(:player, @player_id), lookup: [name: "not player"], defaults: [value: 999])
    assert obj.name == "not player"
    assert obj.value == 999
    assert obj.updated_at == nil
    assert obj.inserted_at == nil
  end

end
