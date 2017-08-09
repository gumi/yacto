defmodule Mix.Tasks.Yacto.GenMigrationTest do
  use PowerAssert

  @migration_version 20170424155528

  test "mix yacto.gen.migration single" do
    dir = Yacto.Migration.Util.get_migration_dir(:gen_migration)
    _ = File.rm_rf(dir)

    path = Yacto.Migration.Util.get_migration_path(:gen_migration, @migration_version)

    Mix.Task.run "yacto.gen.migration", ["--version", Integer.to_string(@migration_version)]

    source = File.read!(path)
    v1 = [{GenMigration.Player, %Yacto.Migration.Structure{}, Yacto.Migration.Structure.from_schema(GenMigration.Player)},
          {GenMigration.Player2, %Yacto.Migration.Structure{}, Yacto.Migration.Structure.from_schema(GenMigration.Player2)},
          {GenMigration.Player3, %Yacto.Migration.Structure{}, Yacto.Migration.Structure.from_schema(GenMigration.Player3)},
          {GenMigration.Item, %Yacto.Migration.Structure{}, Yacto.Migration.Structure.from_schema(GenMigration.Item)}]
    expected = Yacto.Migration.GenMigration.generate_source(GenMigration, v1, @migration_version)
    assert expected == source
    _ = File.rm(path)
  end
end
