defmodule Yacto.XATest do
  use PowerAssert
  doctest Yacto.XA
  require Ecto.Query

  test "Single Transaction" do
    :result = Yacto.XA.transaction([Yacto.XATest.Repo1], fn -> :result end)
  end

  test "Multi Transaction without XA" do
    :result =
      Yacto.XA.transaction([Yacto.XATest.Repo0, Yacto.XATest.Repo1], fn -> :result end, noxa: true)
  end

  test "XA Transaction" do
    Yacto.XA.transaction([Yacto.XATest.Repo0, Yacto.XATest.Repo1], fn ->
      {:ok, _player0} = Yacto.XATest.Repo0.insert(%Yacto.XATest.Player{name: "foo", value: 10})
      {:ok, _player1} = Yacto.XATest.Repo1.insert(%Yacto.XATest.Player{name: "bar", value: 20})
    end)

    value =
      Yacto.XA.transaction([Yacto.XATest.Repo0, Yacto.XATest.Repo1], fn ->
        player0 =
          Yacto.XATest.Player
          |> Ecto.Query.where(name: "foo")
          |> Ecto.Query.lock("FOR UPDATE")
          |> Yacto.XATest.Repo0.one()

        player1 =
          Yacto.XATest.Player
          |> Ecto.Query.where(name: "bar")
          |> Ecto.Query.lock("FOR UPDATE")
          |> Yacto.XATest.Repo1.one()

        value = player0.value * player1.value

        {:ok, _} =
          player0
          |> Ecto.Changeset.change(value: value)
          |> Yacto.XATest.Repo0.update()

        value
      end)

    assert 200 == value

    assert_raise(RuntimeError, "error", fn ->
      Yacto.XA.transaction([Yacto.XATest.Repo0, Yacto.XATest.Repo1], fn ->
        player0 =
          Yacto.XATest.Player
          |> Ecto.Query.where(name: "foo")
          |> Ecto.Query.lock("FOR UPDATE")
          |> Yacto.XATest.Repo0.one()

        player1 =
          Yacto.XATest.Player
          |> Ecto.Query.where(name: "bar")
          |> Ecto.Query.lock("FOR UPDATE")
          |> Yacto.XATest.Repo1.one()

        {:ok, _} =
          player0
          |> Ecto.Changeset.change(value: player0.value * player1.value)
          |> Yacto.XATest.Repo0.update()

        raise "error"
      end)
    end)

    player0 = Yacto.XATest.Player |> Ecto.Query.where(name: "foo") |> Yacto.XATest.Repo0.one()
    assert player0.value == 200
  end

  test "Nested XA transaction has error" do
    # single transaction in XA transaction
    assert_raise(
      RuntimeError,
      "repo Elixir.Yacto.XATest.Repo0 is already in XA transaction.",
      fn ->
        [Yacto.XATest.Repo0, Yacto.XATest.Repo1]
        |> Yacto.XA.transaction(fn ->
          [Yacto.XATest.Repo0]
          |> Yacto.XA.transaction(fn -> :ok end)
        end)
      end
    )

    # XA transaction in XA transaction
    assert_raise(
      RuntimeError,
      "repo Elixir.Yacto.XATest.Repo0 is already in XA transaction.",
      fn ->
        [Yacto.XATest.Repo0, Yacto.XATest.Repo1]
        |> Yacto.XA.transaction(fn ->
          [Yacto.XATest.Repo0, Yacto.XATest.Repo1]
          |> Yacto.XA.transaction(fn -> :ok end)
        end)
      end
    )

    # XA transaction in single transaction
    assert_raise(
      RuntimeError,
      "repo Elixir.Yacto.XATest.Repo1 is already in transaction. XA transaction requires not in transaction.",
      fn ->
        [Yacto.XATest.Repo1]
        |> Yacto.XA.transaction(fn ->
          [Yacto.XATest.Repo0, Yacto.XATest.Repo1]
          |> Yacto.XA.transaction(fn -> :ok end)
        end)
      end
    )

    # signle transaction in single transaction (not error)
    [Yacto.XATest.Repo1]
    |> Yacto.XA.transaction(fn ->
      [Yacto.XATest.Repo1]
      |> Yacto.XA.transaction(fn -> :ok end)
    end)
  end

  test "Single Transaction rollback" do
    assert_raise(Yacto.XA.RollbackError, "The transaction is rolled-back. reason: :error", fn ->
      Yacto.XA.transaction([Yacto.XATest.Repo1], fn ->
        Yacto.XA.rollback(Yacto.XATest.Repo1, :error)
      end)
    end)
  end

  test "Multi Transaction without XA rollback" do
    assert_raise(Yacto.XA.RollbackError, "The transaction is rolled-back. reason: :error", fn ->
      Yacto.XA.transaction(
        [Yacto.XATest.Repo0, Yacto.XATest.Repo1],
        fn ->
          Yacto.XA.rollback(Yacto.XATest.Repo1, :error)
        end,
        noxa: true
      )
    end)
  end

  test "XA Transaction rollback" do
    assert_raise(Yacto.XA.RollbackError, "The transaction is rolled-back. reason: :error", fn ->
      Yacto.XA.transaction([Yacto.XATest.Repo0, Yacto.XATest.Repo1], fn ->
        {:ok, _player0} =
          Yacto.XATest.Repo0.insert(%Yacto.XATest.Player{name: "rollfoo", value: 10})

        {:ok, _player1} =
          Yacto.XATest.Repo1.insert(%Yacto.XATest.Player{name: "rollbar", value: 20})

        Yacto.XA.rollback(Yacto.XATest.Repo0, :error)
      end)
    end)

    player0 = Yacto.XATest.Player |> Ecto.Query.where(name: "rollfoo") |> Yacto.XATest.Repo0.one()
    assert player0 == nil
    player1 = Yacto.XATest.Player |> Ecto.Query.where(name: "rollbar") |> Yacto.XATest.Repo1.one()
    assert player1 == nil

    Yacto.XA.transaction([Yacto.XATest.Repo0, Yacto.XATest.Repo1], fn ->
      {:ok, _player0} =
        Yacto.XATest.Repo0.insert(%Yacto.XATest.Player{name: "rollfoo", value: 10})

      {:ok, _player1} =
        Yacto.XATest.Repo1.insert(%Yacto.XATest.Player{name: "rollbar", value: 20})
    end)

    player0 = Yacto.XATest.Player |> Ecto.Query.where(name: "rollfoo") |> Yacto.XATest.Repo0.one()
    assert player0.value == 10
    player1 = Yacto.XATest.Player |> Ecto.Query.where(name: "rollbar") |> Yacto.XATest.Repo1.one()
    assert player1.value == 20
  end
end
