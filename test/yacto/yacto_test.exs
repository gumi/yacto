defmodule YactoTest do
  use PowerAssert

  test "Yacto.transaction" do
    result =
      Yacto.transaction([:default, {:player, "player_id1"}, {:player, "player_id2"}], fn ->
        :ok
      end)

    assert :ok = result
  end
end
