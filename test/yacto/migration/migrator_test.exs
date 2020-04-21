defmodule Yacto.Migration.MigratorTest do
  use PowerAssert

  @databases %{
    default: %{module: Yacto.DB.Single, repo: Yacto.MigratorTest.Repo1},
    player: %{module: Yacto.DB.Shard, repos: [Yacto.MigratorTest.Repo0, Yacto.MigratorTest.Repo1]}
  }

  setup do
    repo0_config = [
      database: "yacto_migrator_repo0",
      username: "root",
      password: "",
      hostname: "localhost",
      port: 3306
    ]

    repo1_config = [
      database: "yacto_migrator_repo1",
      username: "root",
      password: "",
      hostname: "localhost",
      port: 3306
    ]

    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.MigratorTest.Repo0, repo0_config})
    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.MigratorTest.Repo1, repo1_config})

    for {repo, config} <- [
          {Yacto.MigratorTest.Repo0, repo0_config},
          {Yacto.MigratorTest.Repo1, repo1_config}
        ] do
      _ = repo.__adapter__.storage_down(config)
      :ok = repo.__adapter__.storage_up(config)
    end

    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir(:yacto))
    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir_for_gen())

    Application.put_env(:yacto, :databases, @databases)
    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :databases) end)

    :ok
  end

  test "１ファイルずつマイグレーションファイルの生成とマイグレートを行う" do
    schemas = [Yacto.MigratorTest.Player, Yacto.MigratorTest.Player2, Yacto.MigratorTest.Player3]

    Enum.reduce(schemas, nil, fn schema, prev_migration ->
      schema_name = to_string(schema.__base_schema__())
      {:ok, now} = DateTime.now("Etc/UTC")
      {type, migrate, version} = Yacto.Migration.GenMigration.generate(schema, prev_migration)

      operation =
        case type do
          :created -> :create
          :changed -> :change
          :deleted -> :delete
        end

      migration_file =
        Yacto.Migration.File.new(schema_name, version, schema.dbname(), operation, now)

      migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()
      {:ok, _} = Yacto.Migration.File.save(migrate, migration_dir, migration_file)

      {migration_files, []} =
        Yacto.Migration.File.list_migration_files(migration_dir, schema_name)

      Yacto.Migration.Migrator.up(
        :yacto,
        Yacto.MigratorTest.Repo0,
        schema.__base_schema__(),
        migration_dir,
        migration_files,
        db_opts: [databases: @databases]
      )

      [{mod, _}] = Code.compile_string(migrate)
      mod
    end)

    # Yacto.MigratorTest.Player3 のテーブルが作られているはずなので、
    # テーブルに対して insert したり SHOW CREATE TABLE を見たりする
    player = %Yacto.MigratorTest.Player3{value: "bar", text: ""}
    player = Yacto.MigratorTest.Repo0.insert!(player)

    assert [player] == Yacto.MigratorTest.Repo0.all(Yacto.MigratorTest.Player3)

    expect = """
    CREATE TABLE `yacto_migratortest_player` (
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

  test "mix yacto.migrate --repo=... すると、その repo だけにマイグレートが発生する" do
    migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()
    _ = File.rm_rf(migration_dir)

    Application.put_env(:yacto, :ignore_migration_schemas, [
      Yacto.MigratorTest.Player2,
      Yacto.MigratorTest.Player3,
      Yacto.MigratorTest.DropFieldWithIndex2
    ])

    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

    Mix.Task.rerun("yacto.gen.migration", [
      "--prefix",
      "Yacto.MigratorTest",
      "--migration-dir",
      migration_dir
    ])

    Mix.Task.rerun("yacto.migrate", [
      "--repo",
      "Yacto.MigratorTest.Repo0",
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

    player2 = %Yacto.MigratorTest.Player{name: "foo", value: 200}
    player2 = Yacto.MigratorTest.Repo1.insert!(player2)
    assert [player2] == Yacto.MigratorTest.Repo1.all(Yacto.MigratorTest.Player)

    item = %Yacto.MigratorTest.Item{name: "item"}
    item = Yacto.MigratorTest.Repo1.insert!(item)
    assert [item] == Yacto.MigratorTest.Repo1.all(Yacto.MigratorTest.Item)

    # 何もマイグレートされないが、エラーも発生しないはず
    Mix.Task.rerun("yacto.migrate", [
      "--repo",
      "Yacto.MigratorTest.Repo1",
      "--migration-dir",
      migration_dir
    ])
  end

  test "Yacto.MigratorTest.UnsignedBigInteger" do
    migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()

    Application.put_env(:yacto, :ignore_migration_schemas, [
      Yacto.MigratorTest.Player2,
      Yacto.MigratorTest.Player3,
      Yacto.MigratorTest.DropFieldWithIndex2
    ])

    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

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

    Application.put_env(:yacto, :ignore_migration_schemas, [
      Yacto.MigratorTest.Player2,
      Yacto.MigratorTest.Player3,
      Yacto.MigratorTest.DropFieldWithIndex2
    ])

    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

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

    Application.put_env(:yacto, :ignore_migration_schemas, [
      Yacto.MigratorTest.Player2,
      Yacto.MigratorTest.Player3,
      Yacto.MigratorTest.DropFieldWithIndex2
    ])

    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

    Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigratorTest"])
    Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

    record = %Yacto.MigratorTest.Coin{}
    record = Yacto.MigratorTest.Repo1.insert!(record)
    assert record.type == :common_coin
  end

  test "フィールドの削除とインデックスの削除が同時に行われた場合に正しくマイグレーションできる" do
    migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()

    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

    Application.put_env(:yacto, :ignore_migration_schemas, [
      Yacto.MigratorTest.Player2,
      Yacto.MigratorTest.Player3,
      Yacto.MigratorTest.DropFieldWithIndex2
    ])

    Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigratorTest"])
    Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

    Application.put_env(:yacto, :ignore_migration_schemas, [
      Yacto.MigratorTest.Player2,
      Yacto.MigratorTest.Player3,
      Yacto.MigratorTest.DropFieldWithIndex
    ])

    Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigratorTest"])
    Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

    expect = """
    CREATE TABLE `yacto_migratortest_dropfieldwithindex` (
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

  test "マイグレートでテーブルの削除ができる" do
    migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()

    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

    Application.put_env(:yacto, :ignore_migration_schemas, [
      Yacto.MigratorTest.Player2,
      Yacto.MigratorTest.Player3,
      Yacto.MigratorTest.DropFieldWithIndex2
    ])

    Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigratorTest"])
    Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

    # これで Coin テーブルが削除されるはず
    Application.put_env(:yacto, :ignore_migration_schemas, [
      Yacto.MigratorTest.Coin,
      Yacto.MigratorTest.Player2,
      Yacto.MigratorTest.Player3,
      Yacto.MigratorTest.DropFieldWithIndex2
    ])

    Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigratorTest"])
    Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

    actual =
      Ecto.Adapters.SQL.query!(
        Yacto.MigratorTest.Repo1,
        "SHOW TABLES",
        []
      ).rows
      |> Enum.map(&Enum.at(&1, 0))
      |> Enum.sort()

    expected = [
      "player",
      "yacto_migratortest_customprimarykey",
      "yacto_migratortest_dropfieldwithindex",
      "yacto_migratortest_item",
      "yacto_migratortest_unsignedbiginteger",
      "yacto_schema_migrations"
    ]

    assert expected == actual
  end
end
