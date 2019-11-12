defmodule Yacto.GenMigrationTest2 do
  use PowerAssert

  test "foo" do
    player = Yacto.Migration.GenMigration2.generate(Yacto.GenMigrationTest.Player)
    IO.puts(player)
    IO.inspect(Code.eval_string(player))

    player2 =
      Yacto.Migration.GenMigration2.generate(
        Yacto.GenMigrationTest.Player2,
        Yacto.GenMigrationTest.Player.Migration0000
      )

    IO.puts(player2)
    IO.inspect(Code.eval_string(player2))

    player3 =
      Yacto.Migration.GenMigration2.generate(
        Yacto.GenMigrationTest.Player3,
        Yacto.GenMigrationTest.Player.Migration0001
      )

    IO.puts(player3)
    IO.inspect(Code.eval_string(player3))
  end
end
