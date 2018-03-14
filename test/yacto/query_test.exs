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

  test "Yacto.Query.get_by_for_update" do
    repo = Yacto.QueryTest.Item.repo()
    obj = repo.get_by_for_update!(Yacto.QueryTest.Item, name: "foo")

    assert obj.name == "foo"
    assert obj.quantity == 100

    repo = Yacto.QueryTest.Player.repo(@player_id)
    obj = repo.get_by_for_update!(Yacto.QueryTest.Player, name: "player")

    assert obj.name == "player"
    assert obj.value == 1000
  end

  defp test_get_or_new(lock) do
    repo = Yacto.QueryTest.Item.repo()

    {obj, false} =
      if lock do
        repo.get_or_insert_for_update(
          Yacto.QueryTest.Item,
          [name: "foo"],
          Ecto.Changeset.change(%Yacto.QueryTest.Item{name: "foo", quantity: 1000})
        )
      else
        repo.get_or_new(Yacto.QueryTest.Item, [name: "foo"], %Yacto.QueryTest.Item{
          name: "foo",
          quantity: 1000
        })
      end

    assert obj.name == "foo"
    assert obj.quantity == 100

    {obj, true} =
      if lock do
        repo.get_or_insert_for_update(
          Yacto.QueryTest.Item,
          [name: "bar"],
          Ecto.Changeset.change(%Yacto.QueryTest.Item{name: "bar", quantity: 1000})
        )
      else
        repo.get_or_new(Yacto.QueryTest.Item, [name: "bar"], %Yacto.QueryTest.Item{
          name: "bar",
          quantity: 1000
        })
      end

    assert obj.name == "bar"
    assert obj.quantity == 1000

    repo = Yacto.QueryTest.Player.repo(@player_id)

    {obj, false} =
      if lock do
        repo.get_or_insert_for_update(
          Yacto.QueryTest.Player,
          [name: "player"],
          Ecto.Changeset.change(%Yacto.QueryTest.Player{name: "player", value: 999})
        )
      else
        repo.get_or_new(Yacto.QueryTest.Player, [name: "player"], %Yacto.QueryTest.Player{
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
        repo.get_or_insert_for_update(
          Yacto.QueryTest.Player,
          [name: "not player"],
          Ecto.Changeset.change(%Yacto.QueryTest.Player{name: "not player", value: 999})
        )
      else
        repo.get_or_new(Yacto.QueryTest.Player, [name: "not player"], %Yacto.QueryTest.Player{
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

  test "Yacto.Repo.get_or_new with no lock" do
    test_get_or_new(false)
  end

  test "Yacto.Repo.get_or_new with lock" do
    test_get_or_new(true)
  end
end
