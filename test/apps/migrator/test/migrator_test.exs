defmodule MigratorTest do
  use PowerAssert

  test "run migration" do
    Mix.Task.rerun("ecto.drop")
    Mix.Task.rerun("ecto.create")

    {:ok, _} = Migrator.Repo0.start_link()

    v1 = [
      {Migrator.Player, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Migrator.Player)}
    ]

    v2 = [
      {Migrator.Player, Yacto.Migration.Structure.from_schema(Migrator.Player),
       Yacto.Migration.Structure.from_schema(Migrator.Player2)}
    ]

    v3 = [
      {Migrator.Player, Yacto.Migration.Structure.from_schema(Migrator.Player2),
       Yacto.Migration.Structure.from_schema(Migrator.Player3)}
    ]

    for {v, version} <- [
          {v1, 20_170_424_162_530},
          {v2, 20_170_424_162_533},
          {v3, 20_170_424_162_534}
        ] do
      source = Yacto.Migration.GenMigration.generate_source(Migrator, v, version)

      try do
        File.write!("migration_test.exs", source)
        migrations = Yacto.Migration.Util.load_migrations(["migration_test.exs"])
        schemas = Yacto.Migration.Util.get_all_schema(:migrator)
        :ok = Yacto.Migration.Migrator.up(:migrator, Migrator.Repo0, schemas, migrations)
      after
        File.rm!("migration_test.exs")
        Code.unload_files(["migration_test.exs"])
      end
    end

    player = %Migrator.Player3{value: "bar", text: ""}
    player = Migrator.Repo0.insert!(player)

    assert [player] == Migrator.Repo0.all(Migrator.Player3)

    expect = """
    CREATE TABLE `migrator_player3` (
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
        Migrator.Repo0,
        "SHOW CREATE TABLE #{Migrator.Player3.__schema__(:source)}",
        []
      ).rows
      |> Enum.at(0)
      |> Enum.at(1)

    assert String.trim_trailing(expect) == actual
  end

  test "run migration 2" do
    Mix.Task.rerun("ecto.drop")
    Mix.Task.rerun("ecto.create")

    {:ok, _} = Migrator.Repo0.start_link()

    v1 = [
      {Migrator.Player, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Migrator.Player)}
    ]

    v2 = [
      {Migrator.Player, Yacto.Migration.Structure.from_schema(Migrator.Player),
       Yacto.Migration.Structure.from_schema(Migrator.Player2)}
    ]

    source = Yacto.Migration.GenMigration.generate_source(Migrator, v1, 20_170_424_162_530)
    File.write!("migration_test_1.exs", source)
    source = Yacto.Migration.GenMigration.generate_source(Migrator, v2, 20_170_424_162_533)
    File.write!("migration_test_2.exs", source)

    try do
      migrations =
        Yacto.Migration.Util.load_migrations(["migration_test_1.exs", "migration_test_2.exs"])

      schemas = Yacto.Migration.Util.get_all_schema(:migrator)
      :ok = Yacto.Migration.Migrator.up(:migrator, Migrator.Repo0, schemas, migrations)
    after
      File.rm!("migration_test_1.exs")
      File.rm!("migration_test_2.exs")
      Code.unload_files(["migration_test_1.exs", "migration_test_2.exs"])
    end

    player = %Migrator.Player2{name2: "foo", value: "bar"}
    player = Migrator.Repo0.insert!(player)

    assert [player] == Migrator.Repo0.all(Migrator.Player2)
  end

  test "Yacto.Migration.Migrator.migrate" do
    Mix.Task.rerun("ecto.drop")
    Mix.Task.rerun("ecto.create")

    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir(:migrator))
    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir_for_gen())

    Mix.Task.rerun("yacto.gen.migration", [])
    Mix.Task.rerun("yacto.migrate", ["--repo", "Migrator.Repo0", "--app", "migrator"])

    player = %Migrator.Player{name: "foo", value: 100}
    player = Migrator.Repo0.insert!(player)
    player = Map.drop(player, [:inserted_at, :updated_at])

    assert [player] ==
             Enum.map(
               Migrator.Repo0.all(Migrator.Player),
               &Map.drop(&1, [:inserted_at, :updated_at])
             )

    Mix.Task.rerun("yacto.migrate", ["--repo", "Migrator.Repo1"])

    player2 = %Migrator.Player2{name2: "foo", value: "bar"}
    player2 = Migrator.Repo1.insert!(player2)
    assert [player2] == Migrator.Repo1.all(Migrator.Player2)

    item = %Migrator.Item{name: "item"}
    item = Migrator.Repo1.insert!(item)
    assert [item] == Migrator.Repo1.all(Migrator.Item)

    # nothing is migrated
    Mix.Task.rerun("yacto.migrate", ["--repo", "Migrator.Repo1"])
  end

  test "Migrator.UnsignedBigInteger" do
    Mix.Task.rerun("ecto.drop")
    Mix.Task.rerun("ecto.create")

    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir(:migrator))
    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir_for_gen())

    Mix.Task.rerun("yacto.gen.migration", [])
    Mix.Task.rerun("yacto.migrate", ["--repo", "Migrator.Repo1", "--app", "migrator"])

    bigint = %Migrator.UnsignedBigInteger{user_id: 12_345_678_901_234_567_890}
    bigint = Migrator.Repo1.insert!(bigint)
    assert [bigint] == Migrator.Repo1.all(Migrator.UnsignedBigInteger)
  end

  test "Migrator.CustomPrimaryKey" do
    Mix.Task.rerun("ecto.drop")
    Mix.Task.rerun("ecto.create")

    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir(:migrator))
    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir_for_gen())

    Mix.Task.rerun("yacto.gen.migration", [])
    Mix.Task.rerun("yacto.migrate", ["--repo", "Migrator.Repo1", "--app", "migrator"])

    pk = String.duplicate("a", 10)
    record = %Migrator.CustomPrimaryKey{name: "1234"}
    record = Migrator.Repo1.insert!(record)
    assert pk == record.id
    assert [record] == Migrator.Repo1.all(Migrator.CustomPrimaryKey)
  end
end
