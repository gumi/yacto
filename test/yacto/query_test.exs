defmodule Yacto.QueryTest do
  use PowerAssert
  require Ecto.Query

  @player_id "player_id"

  setup do
    repo_default = Yacto.DB.repo(:default)
    _item = repo_default.insert!(%Yacto.QueryTest.Item{name: "foo", quantity: 100})

    repo_player = Yacto.DB.repo(:player, @player_id)
    _player = repo_player.insert!(%Yacto.QueryTest.Player{name: "player", value: 1000})

    ExUnit.Callbacks.on_exit(fn -> cleanup() end)

    :ok
  end

  defp cleanup() do
    repo_default = Yacto.DB.repo(:default)
    repo_player = Yacto.DB.repo(:player, @player_id)
    Yacto.QueryTest.Item |> Ecto.Query.where([_u], true) |> repo_default.delete_all()
    Yacto.QueryTest.Player |> Ecto.Query.where([_u], true) |> repo_player.delete_all()
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

  defp test_get_or_new(lock) do
    {obj, false} = Yacto.Query.get_or_new(Yacto.QueryTest.Item, Yacto.DB.repo(:default), lock: lock, lookup: [name: "foo"], defaults: [quantity: 1000])
    assert obj.name == "foo"
    assert obj.quantity == 100
    {obj, true} = Yacto.Query.get_or_new(Yacto.QueryTest.Item, Yacto.DB.repo(:default), lock: lock, lookup: [name: "bar"], defaults: [quantity: 1000])
    assert obj.name == "bar"
    assert obj.quantity == 1000

    {obj, false} = Yacto.Query.get_or_new(Yacto.QueryTest.Player, Yacto.DB.repo(:player, @player_id), lock: lock, lookup: [name: "player"], defaults: [value: 999])
    assert obj.name == "player"
    assert obj.value == 1000
    assert obj.updated_at != nil
    assert obj.inserted_at != nil

    {obj, true} = Yacto.Query.get_or_new(Yacto.QueryTest.Player, Yacto.DB.repo(:player, @player_id), lock: lock, lookup: [name: "not player"], defaults: [value: 999])
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

  test "Yacto.Query.get_or_new with no lock" do
    test_get_or_new(false)
  end

  test "Yacto.Query.get_or_new with lock" do
    test_get_or_new(true)
  end

  test "Yacto.Query.create" do
    record = Yacto.Query.create(Yacto.QueryTest.Item, Yacto.DB.repo(:default), fields: [name: "test", quantity: 80])
    assert record.id != nil
    assert record.name == "test"
    assert record.quantity == 80

    # duplicate
    assert_raise Ecto.ConstraintError, fn ->
      Yacto.Query.create(Yacto.QueryTest.Item, Yacto.DB.repo(:default), fields: [id: record.id, name: "test", quantity: 80])
    end
  end

  test "Yacto.Query.save" do
    record = Yacto.Query.create(Yacto.QueryTest.Item, Yacto.DB.repo(:default), fields: [name: "test", quantity: 80])
    record2 = %{record | name: "foo", quantity: 20}
    Yacto.Query.save(Yacto.DB.repo(:default), record: record2)
  end
end
