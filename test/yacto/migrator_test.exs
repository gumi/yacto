defmodule Yacto.MigratorTest do
  use PowerAssert

  @databases %{
    default: %{module: Yacto.DB.Single, repo: Yacto.MigratorTest.Repo1},
    player: %{module: Yacto.DB.Shard, repos: [Yacto.MigratorTest.Repo0, Yacto.MigratorTest.Repo1]}
  }

  setup do
    repo0_config = [
      database: "migrator_repo0",
      username: "root",
      password: "",
      hostname: "localhost",
      port: 3306
    ]

    repo1_config = [
      database: "migrator_repo1",
      username: "root",
      password: "",
      hostname: "localhost",
      port: 3306
    ]

    for {repo, config} <- [
          {Yacto.MigratorTest.Repo0, repo0_config},
          {Yacto.MigratorTest.Repo1, repo1_config}
        ] do
      _ = repo.__adapter__.storage_down(config)
      :ok = repo.__adapter__.storage_up(config)
    end

    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.MigratorTest.Repo0, repo0_config})
    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.MigratorTest.Repo1, repo1_config})

    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir(:yacto))
    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir_for_gen())

    Application.put_env(:yacto, :databases, @databases)
    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :databases) end)

    :ok
  end

  test "run migration" do
    v1 = [
      {Yacto.MigratorTest.Player, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.Player)}
    ]

    v2 = [
      {Yacto.MigratorTest.Player,
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.Player),
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.Player2)}
    ]

    v3 = [
      {Yacto.MigratorTest.Player,
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.Player2),
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.Player3)}
    ]

    try do
      for {v, version, preview_version, save_file, load_files} <- [
            {v1, 20_170_424_162_530, nil, "mig_1.exs", ["mig_1.exs"]},
            {v2, 20_170_424_162_533, 20_170_424_162_530, "mig_2.exs", ["mig_1.exs", "mig_2.exs"]},
            {v3, 20_170_424_162_534, 20_170_424_162_533, "mig_3.exs",
             ["mig_1.exs", "mig_2.exs", "mig_3.exs"]}
          ] do
        source =
          Yacto.Migration.GenMigration.generate_source(
            Yacto.MigratorTest,
            v,
            version,
            preview_version
          )

        File.write!(save_file, source)
        migrations = Yacto.Migration.Util.load_migrations(load_files)

        schemas = Yacto.Migration.Util.get_all_schema(:yacto, "Yacto.MigratorTest")

        :ok =
          Yacto.Migration.Migrator.up(
            :yacto,
            Yacto.MigratorTest.Repo0,
            schemas,
            migrations,
            db_opts: [databases: @databases]
          )
      end
    after
      File.rm("mig_1.exs")
      File.rm("mig_2.exs")
      File.rm("mig_3.exs")
      Code.unload_files(["mig_1.exs"])
      Code.unload_files(["mig_2.exs"])
      Code.unload_files(["mig_3.exs"])
    end

    player = %Yacto.MigratorTest.Player3{value: "bar", text: ""}
    player = Yacto.MigratorTest.Repo0.insert!(player)

    assert [player] == Yacto.MigratorTest.Repo0.all(Yacto.MigratorTest.Player3)

    expect = """
    CREATE TABLE `yacto_migratortest_player3` (
      `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
      `value` varchar(255) DEFAULT NULL,
      `name3` varchar(100) NOT NULL DEFAULT 'hage',
      `text_data` text NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `name3_value_index` (`name3`,`value`),
      KEY `value_name3_index` (`value`,`name3`)
    ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8
    """

    actual =
      Ecto.Adapters.SQL.query!(
        Yacto.MigratorTest.Repo0,
        "SHOW CREATE TABLE #{Yacto.MigratorTest.Player3.__schema__(:source)}",
        []
      ).rows
      |> Enum.at(0)
      |> Enum.at(1)

    assert String.trim_trailing(expect) == actual
  end

  test "run migration 2" do
    v1 = [
      {Yacto.MigratorTest.Player, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.Player)}
    ]

    v2 = [
      {Yacto.MigratorTest.Player,
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.Player),
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.Player2)}
    ]

    source =
      Yacto.Migration.GenMigration.generate_source(
        Yacto.MigratorTest,
        v1,
        20_170_424_162_530,
        nil
      )

    File.write!("migration_test_1.exs", source)

    source =
      Yacto.Migration.GenMigration.generate_source(
        Yacto.MigratorTest,
        v2,
        20_170_424_162_533,
        20_170_424_162_530
      )

    File.write!("migration_test_2.exs", source)

    try do
      migrations =
        Yacto.Migration.Util.load_migrations(["migration_test_1.exs", "migration_test_2.exs"])

      schemas = Yacto.Migration.Util.get_all_schema(:yacto, "Yacto.MigratorTest")

      :ok =
        Yacto.Migration.Migrator.up(
          :yacto,
          Yacto.MigratorTest.Repo0,
          schemas,
          migrations,
          db_opts: [databases: @databases]
        )
    after
      File.rm!("migration_test_1.exs")
      File.rm!("migration_test_2.exs")
      Code.unload_files(["migration_test_1.exs", "migration_test_2.exs"])
    end

    player = %Yacto.MigratorTest.Player2{name2: "foo", value: "bar"}
    player = Yacto.MigratorTest.Repo0.insert!(player)

    assert [player] == Yacto.MigratorTest.Repo0.all(Yacto.MigratorTest.Player2)
  end

  test "Yacto.Migration.Migrator.migrate" do
    migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()
    Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigratorTest"])

    Mix.Task.rerun("yacto.migrate", [
      "--repo",
      "Yacto.MigratorTest.Repo0",
      "--app",
      "yacto",
      "--migration-dir",
      migration_dir
    ])

    player = %Yacto.MigratorTest.Player{name: "foo", value: 100}
    player = Yacto.MigratorTest.Repo0.insert!(player)
    player = Map.drop(player, [:inserted_at, :updated_at])

    assert [player] ==
             Enum.map(
               Yacto.MigratorTest.Repo0.all(Yacto.MigratorTest.Player),
               &Map.drop(&1, [:inserted_at, :updated_at])
             )

    Mix.Task.rerun("yacto.migrate", [
      "--repo",
      "Yacto.MigratorTest.Repo1",
      "--migration-dir",
      migration_dir
    ])

    player2 = %Yacto.MigratorTest.Player2{name2: "foo", value: "bar"}
    player2 = Yacto.MigratorTest.Repo1.insert!(player2)
    assert [player2] == Yacto.MigratorTest.Repo1.all(Yacto.MigratorTest.Player2)

    item = %Yacto.MigratorTest.Item{name: "item"}
    item = Yacto.MigratorTest.Repo1.insert!(item)
    assert [item] == Yacto.MigratorTest.Repo1.all(Yacto.MigratorTest.Item)

    # nothing is migrated
    Mix.Task.rerun("yacto.migrate", [
      "--repo",
      "Yacto.MigratorTest.Repo1",
      "--migration-dir",
      migration_dir
    ])
  end

  test "Yacto.MigratorTest.UnsignedBigInteger" do
    migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()

    Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigratorTest"])

    Mix.Task.rerun("yacto.migrate", [
      "--repo",
      "Yacto.MigratorTest.Repo1",
      "--app",
      "yacto",
      "--migration-dir",
      migration_dir
    ])

    bigint = %Yacto.MigratorTest.UnsignedBigInteger{user_id: 12_345_678_901_234_567_890}
    bigint = Yacto.MigratorTest.Repo1.insert!(bigint)
    assert [bigint] == Yacto.MigratorTest.Repo1.all(Yacto.MigratorTest.UnsignedBigInteger)
  end

  test "Yacto.MigratorTest.CustomPrimaryKey" do
    migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()

    Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigratorTest"])

    Mix.Task.rerun("yacto.migrate", [
      "--repo",
      "Yacto.MigratorTest.Repo1",
      "--app",
      "yacto",
      "--migration-dir",
      migration_dir
    ])

    pk = String.duplicate("a", 10)
    record = %Yacto.MigratorTest.CustomPrimaryKey{name: "1234"}
    record = Yacto.MigratorTest.Repo1.insert!(record)
    assert pk == record.id
    assert [record] == Yacto.MigratorTest.Repo1.all(Yacto.MigratorTest.CustomPrimaryKey)
  end

  test "Yacto.MigratorTest.Coin" do
    migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()

    Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigratorTest"])
    Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

    record = %Yacto.MigratorTest.Coin{}
    record = Yacto.MigratorTest.Repo1.insert!(record)
    assert record.type == :common_coin
  end

  test "フィールドの削除とインデックスの削除が同時に行われた場合に正しくマイグレーションできる" do
    v1 = [
      {Yacto.MigratorTest.DropFieldWithIndex, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.DropFieldWithIndex)}
    ]

    v2 = [
      {Yacto.MigratorTest.DropFieldWithIndex,
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.DropFieldWithIndex),
       Yacto.Migration.Structure.from_schema(Yacto.MigratorTest.DropFieldWithIndex2)}
    ]

    try do
      for {v, version, preview_version, save_file, load_files} <- [
            {v1, 20_170_424_162_530, nil, "mig_1.exs", ["mig_1.exs"]},
            {v2, 20_170_424_162_533, 20_170_424_162_530, "mig_2.exs", ["mig_1.exs", "mig_2.exs"]}
          ] do
        source =
          Yacto.Migration.GenMigration.generate_source(
            Yacto.MigratorTest,
            v,
            version,
            preview_version
          )

        File.write!(save_file, source)
        migrations = Yacto.Migration.Util.load_migrations(load_files)

        schemas = Yacto.Migration.Util.get_all_schema(:yacto, "Yacto.MigratorTest")

        :ok =
          Yacto.Migration.Migrator.up(
            :yacto,
            Yacto.MigratorTest.Repo1,
            schemas,
            migrations,
            db_opts: [databases: @databases]
          )
      end
    after
      File.rm("mig_1.exs")
      File.rm("mig_2.exs")
      Code.unload_files(["mig_1.exs"])
      Code.unload_files(["mig_2.exs"])
    end

    expect = """
    CREATE TABLE `yacto_migratortest_dropfieldwithindex2` (
      `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
      `value2` varchar(255) NOT NULL,
      PRIMARY KEY (`id`),
      KEY `value2_index` (`value2`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    """

    actual =
      Ecto.Adapters.SQL.query!(
        Yacto.MigratorTest.Repo1,
        "SHOW CREATE TABLE #{Yacto.MigratorTest.DropFieldWithIndex2.__schema__(:source)}",
        []
      ).rows
      |> Enum.at(0)
      |> Enum.at(1)

    assert String.trim_trailing(expect) == actual
  end
end
