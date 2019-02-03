defmodule Mix.Tasks.Yacto.GenMigrationTest do
  use PowerAssert

  @migration_version 20_170_424_155_528
  @migration_version2 20_170_424_155_529

  test "mix yacto.gen.migration single" do
    dir = Yacto.Migration.Util.get_migration_dir_for_gen()
    _ = File.rm_rf(dir)

    path = Yacto.Migration.Util.get_migration_path_for_gen(:gen_migration, @migration_version)

    Mix.Task.rerun("yacto.gen.migration", ["--version", Integer.to_string(@migration_version)])

    source = File.read!(path)

    v1 = [
      {GenMigration.Player, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(GenMigration.Player)},
      {GenMigration.Player2, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(GenMigration.Player2)},
      {GenMigration.Player3, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(GenMigration.Player3)},
      {GenMigration.Item, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(GenMigration.Item)},
      {GenMigration.Coin, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(GenMigration.Coin)},
      {GenMigration.ManyIndex, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(GenMigration.ManyIndex)}
    ]

    expected = Yacto.Migration.GenMigration.generate_source(GenMigration, v1, @migration_version, nil, index_name_max_length: 20)
    assert expected == source

    # if all schemas are not changed, a migration file is not generated
    path = Yacto.Migration.Util.get_migration_path_for_gen(:gen_migration, @migration_version2)
    Mix.Task.rerun("yacto.gen.migration", ["--version", Integer.to_string(@migration_version2)])
    assert !File.exists?(path)
  end
end
