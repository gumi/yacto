defmodule Mix.Tasks.Yacto.Gen.MigrationTest do
  use PowerAssert

  @migration_version 20_170_424_155_528
  @migration_version2 20_170_424_155_529

  setup do
    Application.put_env(:yacto, :migration, index_name_max_length: 20)
    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :migration) end)
  end

  test "mix yacto.gen.migration single" do
    dir = Yacto.Migration.Util.get_migration_dir_for_gen()
    _ = File.rm_rf(dir)

    path = Yacto.Migration.Util.get_migration_path_for_gen(:yacto, @migration_version)

    Mix.Task.rerun("yacto.gen.migration", [
      "--version",
      Integer.to_string(@migration_version),
      "--prefix",
      "Yacto.GenMigrationTest",
      "--migration-dir",
      dir
    ])

    source = File.read!(path)

    v1 = [
      {Yacto.GenMigrationTest.Player, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player)},
      {Yacto.GenMigrationTest.Player2, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player2)},
      {Yacto.GenMigrationTest.Player3, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player3)},
      {Yacto.GenMigrationTest.Item, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Item)},
      {Yacto.GenMigrationTest.Coin, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Coin)},
      {Yacto.GenMigrationTest.ManyIndex, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.ManyIndex)},
      {Yacto.GenMigrationTest.DecimalOption, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.DecimalOption)}
    ]

    expected =
      Yacto.Migration.GenMigration.generate_source(Yacto, v1, @migration_version, nil,
        index_name_max_length: 20
      )

    assert expected == source

    # if all schemas are not changed, a migration file is not generated
    path = Yacto.Migration.Util.get_migration_path_for_gen(:yacto, @migration_version2)

    Mix.Task.rerun("yacto.gen.migration", [
      "--version",
      Integer.to_string(@migration_version2),
      "--prefix",
      "Yacto.GenMigrationTest",
      "--migration-dir",
      dir
    ])

    assert !File.exists?(path)
  end

  @migration_version_del 20_180_424_155_528
  @migration_version_del2 20_180_424_155_529

  test "mix yacto.gen.migration した時にモデルの削除に追従できる" do
    dir = Yacto.Migration.Util.get_migration_dir_for_gen()
    _ = File.rm_rf(dir)
    File.mkdir_p!(dir)

    # 適当なマイグレーション情報を作る
    v1 = [
      {Yacto.GenMigrationTest.Player, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player)},
      {Yacto.GenMigrationTest.PlayerUnknown, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player)},
      {Yacto.GenMigrationTest.Item, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Item)},
      {Yacto.GenMigrationTest.Coin, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Coin)},
      {Yacto.GenMigrationTest.ManyIndex, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.ManyIndex)}
    ]

    migration =
      Yacto.Migration.GenMigration.generate_source(Yacto, v1, @migration_version_del, nil)

    path = Yacto.Migration.Util.get_migration_path_for_gen(:yacto, @migration_version_del)
    File.write!(path, migration)

    # 上記のマイグレーションの状態から、新しいマイグレーションファイルを生成する
    Mix.Task.rerun("yacto.gen.migration", [
      "--version",
      Integer.to_string(@migration_version_del2),
      "--prefix",
      "Yacto.GenMigrationTest",
      "--migration-dir",
      dir
    ])

    # Yacto.GenMigrationTest.PlayerUnknown のモデルは存在しないので、マイグレートした時に削除されるはず
    path2 = Yacto.Migration.Util.get_migration_path_for_gen(:yacto, @migration_version_del2)

    migration2 = File.read!(path2)
    assert String.contains?(migration2, "drop table(\"player\")")
  end
end
