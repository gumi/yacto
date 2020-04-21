defmodule Yacto.Migration.MigrationTest do
  use PowerAssert

  require Ecto.Query

  describe "DB のセットアップが必要なテスト" do
    @databases %{
      default: %{module: Yacto.DB.Single, repo: Yacto.MigrationTest.Repo1},
      player: %{module: Yacto.DB.Shard, repos: [Yacto.MigrationTest.Repo0, Yacto.MigrationTest.Repo1]}
    }

    setup do
      repo0_config = [
        database: "yacto_migration_repo0",
        username: "root",
        password: "",
        hostname: "localhost",
        port: 3306
      ]

      repo1_config = [
        database: "yacto_migration_repo1",
        username: "root",
        password: "",
        hostname: "localhost",
        port: 3306
      ]

      {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.MigrationTest.Repo0, repo0_config})
      {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.MigrationTest.Repo1, repo1_config})

      for {repo, config} <- [
            {Yacto.MigrationTest.Repo0, repo0_config},
            {Yacto.MigrationTest.Repo1, repo1_config}
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
      schemas = [Yacto.MigrationTest.Player, Yacto.MigrationTest.Player2, Yacto.MigrationTest.Player3]

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
          Yacto.MigrationTest.Repo0,
          schema.__base_schema__(),
          migration_dir,
          migration_files,
          db_opts: [databases: @databases]
        )

        [{mod, _}] = Code.compile_string(migrate)
        mod
      end)

      # Yacto.MigrationTest.Player3 のテーブルが作られているはずなので、
      # テーブルに対して insert したり SHOW CREATE TABLE を見たりする
      player = %Yacto.MigrationTest.Player3{value: "bar", text: ""}
      player = Yacto.MigrationTest.Repo0.insert!(player)

      assert [player] == Yacto.MigrationTest.Repo0.all(Yacto.MigrationTest.Player3)

      expect = """
      CREATE TABLE `yacto_migrationtest_player` (
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
          Yacto.MigrationTest.Repo0,
          "SHOW CREATE TABLE #{Yacto.MigrationTest.Player3.__schema__(:source)}",
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
        Yacto.MigrationTest.Player2,
        Yacto.MigrationTest.Player3,
        Yacto.MigrationTest.DropFieldWithIndex2
      ])

      ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

      Mix.Task.rerun("yacto.gen.migration", [
        "--prefix",
        "Yacto.MigrationTest",
        "--migration-dir",
        migration_dir
      ])

      Mix.Task.rerun("yacto.migrate", [
        "--repo",
        "Yacto.MigrationTest.Repo0",
        "--migration-dir",
        migration_dir
      ])

      player = %Yacto.MigrationTest.Player{name: "foo", value: 100}
      player = Yacto.MigrationTest.Repo0.insert!(player)
      player = Map.drop(player, [:inserted_at, :updated_at])

      assert [player] ==
               Enum.map(
                 Yacto.MigrationTest.Repo0.all(Yacto.MigrationTest.Player),
                 &Map.drop(&1, [:inserted_at, :updated_at])
               )

      Mix.Task.rerun("yacto.migrate", [
        "--repo",
        "Yacto.MigrationTest.Repo1",
        "--migration-dir",
        migration_dir
      ])

      player2 = %Yacto.MigrationTest.Player{name: "foo", value: 200}
      player2 = Yacto.MigrationTest.Repo1.insert!(player2)
      assert [player2] == Yacto.MigrationTest.Repo1.all(Yacto.MigrationTest.Player)

      item = %Yacto.MigrationTest.Item{name: "item"}
      item = Yacto.MigrationTest.Repo1.insert!(item)
      assert [item] == Yacto.MigrationTest.Repo1.all(Yacto.MigrationTest.Item)

      # 何もマイグレートされないが、エラーも発生しないはず
      Mix.Task.rerun("yacto.migrate", [
        "--repo",
        "Yacto.MigrationTest.Repo1",
        "--migration-dir",
        migration_dir
      ])
    end

    test "bigint(20) unsigned な型がちゃんとマイグレートできるか確認" do
      migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()

      Application.put_env(:yacto, :ignore_migration_schemas, [
        Yacto.MigrationTest.Player2,
        Yacto.MigrationTest.Player3,
        Yacto.MigrationTest.DropFieldWithIndex2
      ])

      ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

      Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigrationTest"])

      Mix.Task.rerun("yacto.migrate", [
        "--repo",
        "Yacto.MigrationTest.Repo1",
        "--app",
        "yacto",
        "--migration-dir",
        migration_dir
      ])

      bigint = %Yacto.MigrationTest.UnsignedBigInteger{user_id: 12_345_678_901_234_567_890}
      bigint = Yacto.MigrationTest.Repo1.insert!(bigint)
      assert [bigint] == Yacto.MigrationTest.Repo1.all(Yacto.MigrationTest.UnsignedBigInteger)
    end

    test "プライマリキーに MFA を渡してもマイグレートできるか確認する" do
      migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()

      Application.put_env(:yacto, :ignore_migration_schemas, [
        Yacto.MigrationTest.Player2,
        Yacto.MigrationTest.Player3,
        Yacto.MigrationTest.DropFieldWithIndex2
      ])

      ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

      Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigrationTest"])

      Mix.Task.rerun("yacto.migrate", [
        "--repo",
        "Yacto.MigrationTest.Repo1",
        "--app",
        "yacto",
        "--migration-dir",
        migration_dir
      ])

      pk = String.duplicate("a", 10)
      record = %Yacto.MigrationTest.CustomPrimaryKey{name: "1234"}
      record = Yacto.MigrationTest.Repo1.insert!(record)
      assert pk == record.id
      assert [record] == Yacto.MigrationTest.Repo1.all(Yacto.MigrationTest.CustomPrimaryKey)
    end

    test "Ecto.Type で作ったカスタム型がマイグレートできるか確認する" do
      migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()

      Application.put_env(:yacto, :ignore_migration_schemas, [
        Yacto.MigrationTest.Player2,
        Yacto.MigrationTest.Player3,
        Yacto.MigrationTest.DropFieldWithIndex2
      ])

      ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

      Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigrationTest"])
      Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

      record = %Yacto.MigrationTest.Coin{player_id: "player", type_id: :free_coin, platform: "platform", quantity: 10, description: ""}
      record = Yacto.MigrationTest.Repo1.insert!(record)
      assert record.type_id == :free_coin

      # デフォルト値が効くかどうか確認
      record = %Yacto.MigrationTest.Coin{player_id: "player2", platform: "platform2", description: ""}
      record = Yacto.MigrationTest.Repo1.insert!(record)
      assert record.type_id == :common_coin
      assert record.quantity == 0
    end

    test "フィールドの削除とインデックスの削除が同時に行われた場合に正しくマイグレーションできる" do
      migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()

      ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

      Application.put_env(:yacto, :ignore_migration_schemas, [
        Yacto.MigrationTest.Player2,
        Yacto.MigrationTest.Player3,
        Yacto.MigrationTest.DropFieldWithIndex2
      ])

      Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigrationTest"])
      Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

      Application.put_env(:yacto, :ignore_migration_schemas, [
        Yacto.MigrationTest.Player2,
        Yacto.MigrationTest.Player3,
        Yacto.MigrationTest.DropFieldWithIndex
      ])

      Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigrationTest"])
      Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

      expect = """
      CREATE TABLE `yacto_migrationtest_dropfieldwithindex` (
        `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
        `value2` varchar(255) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `value2_index` (`value2`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
      """

      actual =
        Ecto.Adapters.SQL.query!(
          Yacto.MigrationTest.Repo1,
          "SHOW CREATE TABLE #{Yacto.MigrationTest.DropFieldWithIndex2.__schema__(:source)}",
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
        Yacto.MigrationTest.Player2,
        Yacto.MigrationTest.Player3,
        Yacto.MigrationTest.DropFieldWithIndex2
      ])

      Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigrationTest"])
      Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

      # これで Coin テーブルが削除されるはず
      Application.put_env(:yacto, :ignore_migration_schemas, [
        Yacto.MigrationTest.Coin,
        Yacto.MigrationTest.Player2,
        Yacto.MigrationTest.Player3,
        Yacto.MigrationTest.DropFieldWithIndex2
      ])

      Mix.Task.rerun("yacto.gen.migration", ["--prefix", "Yacto.MigrationTest"])
      Mix.Task.rerun("yacto.migrate", ["--app", "yacto", "--migration-dir", migration_dir])

      actual =
        Ecto.Adapters.SQL.query!(
          Yacto.MigrationTest.Repo1,
          "SHOW TABLES",
          []
        ).rows
        |> Enum.map(&Enum.at(&1, 0))
        |> Enum.sort()

      expected = ["player", "yacto_migrationtest_customprimarykey", "yacto_migrationtest_decimaloption", "yacto_migrationtest_dropfieldwithindex", "yacto_migrationtest_item", "yacto_migrationtest_manyindex", "yacto_migrationtest_unsignedbiginteger", "yacto_schema_migrations"]

      assert expected == actual
    end

    test "yacto.gen.migration と yacto.migrate を試す" do
      migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()
      _ = File.rm_rf(migration_dir)

      ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :ignore_migration_schemas) end)

      Application.put_env(:yacto, :ignore_migration_schemas, [
        Yacto.MigrationTest.Player2,
        Yacto.MigrationTest.Player3,
        Yacto.MigrationTest.DropFieldWithIndex2
      ])

      Mix.Task.rerun("yacto.gen.migration", [
        "--prefix",
        "Yacto.MigrationTest",
        "--migration-dir",
        migration_dir
      ])

      Mix.Task.rerun("yacto.migrate", ["--migration-dir", migration_dir])
    end
  end

  describe "マイグレーションファイルが意図した内容になっているかのテスト" do
    @migrate1 """
    defmodule Yacto.MigrationTest.Player.Migration0000 do
      use Ecto.Migration

      def change() do
        create table("player")
        alter table("player") do
          add(:name, :string, [])
          add(:value, :integer, [])
          add(:inserted_at, :naive_datetime, [])
          add(:updated_at, :naive_datetime, [])
        end
        :ok
      end

      def __migration__(:structure) do
        %Yacto.Migration.Structure{field_sources: %{id: :id, inserted_at: :inserted_at, name: :name, updated_at: :updated_at, value: :value}, fields: [:id, :name, :value, :inserted_at, :updated_at], source: "player", types: %{id: :id, inserted_at: :naive_datetime, name: :string, updated_at: :naive_datetime, value: :integer}}
      end

      def __migration__(:version) do
        0
      end
    end
    """

    @migrate2 """
    defmodule Yacto.MigrationTest.Player.Migration0001 do
      use Ecto.Migration

      def change() do
        rename table("player"), to: table("player2")
        alter table("player2") do
          remove(:inserted_at)
          remove(:name)
          remove(:updated_at)
          remove(:value)
          add(:name2, :string, [])
          add(:value, :string, [])
        end
        :ok
      end

      def __migration__(:structure) do
        %Yacto.Migration.Structure{field_sources: %{id: :id, name2: :name2, value: :value}, fields: [:id, :name2, :value], source: "player2", types: %{id: :id, name2: :string, value: :string}}
      end

      def __migration__(:version) do
        1
      end
    end
    """

    @migrate3 """
    defmodule Yacto.MigrationTest.Player.Migration0002 do
      use Ecto.Migration

      def change() do
        rename table("player2"), to: table("yacto_migrationtest_player")
        alter table("yacto_migrationtest_player") do
          remove(:name2)
          add(:name3, :string, [default: "hage", null: false, size: 100])
          add(:text_data, :text, [null: false])
        end
        create index("yacto_migrationtest_player", [:name3, :value], [name: "name3_value_index", unique: true])
        create index("yacto_migrationtest_player", [:value, :name3], [name: "value_name3_index"])
        :ok
      end

      def __migration__(:structure) do
        %Yacto.Migration.Structure{field_sources: %{id: :id, name3: :name3, text: :text_data, value: :value}, fields: [:id, :name3, :value, :text], meta: %{attrs: %{name3: %{default: "hage", null: false, size: 100}, text: %{null: false}}, indices: %{{[:name3, :value], [unique: true]} => true, {[:value, :name3], []} => true}}, source: "yacto_migrationtest_player", types: %{id: :id, name3: :string, text: :text, value: :string}}
      end

      def __migration__(:version) do
        2
      end
    end
    """

    @migrate4 """
    defmodule Yacto.MigrationTest.Player.Migration0003 do
      use Ecto.Migration

      def change() do
        drop table("yacto_migrationtest_player")
        :ok
      end

      def __migration__(:structure) do
        %Yacto.Migration.Structure{}
      end

      def __migration__(:version) do
        3
      end
    end
    """

    test "Yacto.Migration.GenMigration.generate でマイグレーションのソースが出力される" do
      {:created, migrate1, 0} =
        Yacto.Migration.GenMigration.generate(Yacto.MigrationTest.Player, nil)

      assert @migrate1 == migrate1

      [{mod1, _}] = Code.compile_string(migrate1)

      {:changed, migrate2, 1} =
        Yacto.Migration.GenMigration.generate(Yacto.MigrationTest.Player2, mod1)

      assert @migrate2 == migrate2

      [{mod2, _}] = Code.compile_string(migrate2)

      {:changed, migrate3, 2} =
        Yacto.Migration.GenMigration.generate(Yacto.MigrationTest.Player3, mod2)

      assert @migrate3 == migrate3

      [{mod3, _}] = Code.compile_string(migrate3)
      {:deleted, migrate4, 3} = Yacto.Migration.GenMigration.generate(nil, mod3)
      assert @migrate4 == migrate4
    end

    @migrate5 """
    defmodule Yacto.MigrationTest.Item.Migration0000 do
      use Ecto.Migration

      def change() do
        create table("yacto_migrationtest_item")
        alter table("yacto_migrationtest_item") do
          add(:_gen_migration_dummy, :integer, [])
          remove(:id)
        end
        alter table("yacto_migrationtest_item") do
          remove(:_gen_migration_dummy)
          add(:id, :binary_id, [primary_key: true, autogenerate: true])
          add(:name, :string, [null: false])
        end
        :ok
      end

      def __migration__(:structure) do
        %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :binary_id}, field_sources: %{id: :id, name: :name}, fields: [:id, :name], meta: %{attrs: %{name: %{null: false}}, indices: %{}}, source: "yacto_migrationtest_item", types: %{id: :binary_id, name: :string}}
      end

      def __migration__(:version) do
        0
      end
    end
    """

    test "Yacto.Migration.GenMigration.generate でダミー要素が追加されるパターン" do
      {:created, migrate, 0} =
        Yacto.Migration.GenMigration.generate(Yacto.MigrationTest.Item, nil)

      assert @migrate5 == migrate
    end

    @migrate6 """
    defmodule Yacto.MigrationTest.ManyIndex.Migration0000 do
      use Ecto.Migration

      def change() do
        create table("yacto_migrationtest_manyindex")
        alter table("yacto_migrationtest_manyindex") do
          add(:aaaaaa, :string, [])
          add(:bbbbbb, :string, [])
          add(:cccccc, :string, [])
          add(:dddddd, :string, [])
        end
        create index("yacto_migrationtest_manyindex", [:aaaaaa, :bbbbbb, :cccccc, :dddddd], [name: "aaaaaa_bbbb_9a4e1a2f"])
        :ok
      end

      def __migration__(:structure) do
        %Yacto.Migration.Structure{field_sources: %{aaaaaa: :aaaaaa, bbbbbb: :bbbbbb, cccccc: :cccccc, dddddd: :dddddd, id: :id}, fields: [:id, :aaaaaa, :bbbbbb, :cccccc, :dddddd], meta: %{attrs: %{}, indices: %{{[:aaaaaa, :bbbbbb, :cccccc, :dddddd], []} => true}}, source: "yacto_migrationtest_manyindex", types: %{aaaaaa: :string, bbbbbb: :string, cccccc: :string, dddddd: :string, id: :id}}
      end

      def __migration__(:version) do
        0
      end
    end
    """

    test ":index_name_max_length を設定すると長いインデックス名は shrink される" do
      {:created, migrate, 0} =
        Yacto.Migration.GenMigration.generate(Yacto.MigrationTest.ManyIndex, nil,
          index_name_max_length: 20
        )

      assert @migrate6 == migrate
    end

    @migrate7 """
    defmodule Yacto.MigrationTest.DecimalOption.Migration0000 do
      use Ecto.Migration

      def change() do
        create table("yacto_migrationtest_decimaloption")
        alter table("yacto_migrationtest_decimaloption") do
          add(:player_id, :string, [])
          add(:decimal_field, :decimal, [precision: 7, scale: 3])
          add(:name, :string, [null: true])
        end
        :ok
      end

      def __migration__(:structure) do
        %Yacto.Migration.Structure{field_sources: %{decimal_field: :decimal_field, id: :id, name: :name, player_id: :player_id}, fields: [:id, :player_id, :decimal_field, :name], meta: %{attrs: %{decimal_field: %{precision: 7, scale: 3}, name: %{null: true}}, indices: %{}}, source: "yacto_migrationtest_decimaloption", types: %{decimal_field: :decimal, id: :id, name: :string, player_id: :string}}
      end

      def __migration__(:version) do
        0
      end
    end
    """

    test "decimal 型のオプションを付けてマイグレーションファイルが作れるか確認する" do
      {:created, migrate, 0} =
        Yacto.Migration.GenMigration.generate(Yacto.MigrationTest.DecimalOption, nil)

      assert @migrate7 == migrate
    end

    @migrate8 """
    defmodule Yacto.MigrationTest.Coin.Migration0000 do
      use Ecto.Migration

      def change() do
        create table("yacto_migrationtest_coin")
        alter table("yacto_migrationtest_coin") do
          add(:player_id, :string, [null: false])
          add(:type_id, :integer, [default: 2, null: false])
          add(:platform, :string, [null: false])
          add(:quantity, :integer, [default: 0, null: false])
          add(:description, :text, [null: false])
          add(:inserted_at, :naive_datetime, [])
          add(:updated_at, :naive_datetime, [])
        end
        create index("yacto_migrationtest_coin", [:player_id, :type_id, :platform], [name: "player_id_type_id_platform_index", unique: true])
        :ok
      end

      def __migration__(:structure) do
        %Yacto.Migration.Structure{field_sources: %{description: :description, id: :id, inserted_at: :inserted_at, platform: :platform, player_id: :player_id, quantity: :quantity, type_id: :type_id, updated_at: :updated_at}, fields: [:id, :player_id, :type_id, :platform, :quantity, :description, :inserted_at, :updated_at], meta: %{attrs: %{description: %{null: false}, platform: %{null: false}, player_id: %{null: false}, quantity: %{default: 0, null: false}, type_id: %{default: 2, null: false}}, indices: %{{[:player_id, :type_id, :platform], [unique: true]} => true}}, source: "yacto_migrationtest_coin", types: %{description: :text, id: :id, inserted_at: :naive_datetime, platform: :string, player_id: :string, quantity: :integer, type_id: :integer, updated_at: :naive_datetime}}
      end

      def __migration__(:version) do
        0
      end
    end
    """

    test "Ecto.Type で定義したカスタム型フィールドのマイグレーションファイルを作れるか確認する" do
      {:created, migrate, 0} =
        Yacto.Migration.GenMigration.generate(Yacto.MigrationTest.Coin, nil)

      assert @migrate8 == migrate
    end

    test "生成したマイグレーションファイルで実際にマイグレートできるか確認する" do
      repo0 = Yacto.MigrationTest.Repo0

      repo0_config = [
        database: "yacto_migration_repo0",
        username: "root",
        password: "",
        hostname: "localhost",
        port: 3306
      ]

      {:ok, _} = ExUnit.Callbacks.start_supervised({repo0, repo0_config})

      _ = repo0.__adapter__.storage_down(repo0_config)
      :ok = repo0.__adapter__.storage_up(repo0_config)
      Yacto.Migration.SchemaMigration.ensure_schema_migrations_table!(repo0)

      [{mod1, _}] = Code.compile_string(@migrate1)
      Yacto.Migration.Migrator.migrate(:yacto, repo0, Yacto.MigrationTest.Player, mod1)
      [{mod2, _}] = Code.compile_string(@migrate2)
      Yacto.Migration.Migrator.migrate(:yacto, repo0, Yacto.MigrationTest.Player, mod2)
      [{mod3, _}] = Code.compile_string(@migrate3)
      Yacto.Migration.Migrator.migrate(:yacto, repo0, Yacto.MigrationTest.Player, mod3)
      [{mod4, _}] = Code.compile_string(@migrate4)
      Yacto.Migration.Migrator.migrate(:yacto, repo0, Yacto.MigrationTest.Player, mod4)

      [{mod5, _}] = Code.compile_string(@migrate5)
      Yacto.Migration.Migrator.migrate(:yacto, repo0, Yacto.MigrationTest.Item, mod5)

      [{mod6, _}] = Code.compile_string(@migrate6)
      Yacto.Migration.Migrator.migrate(:yacto, repo0, Yacto.MigrationTest.ManyIndex, mod6)

      [{mod7, _}] = Code.compile_string(@migrate7)
      Yacto.Migration.Migrator.migrate(:yacto, repo0, Yacto.MigrationTest.DecimalOption, mod7)

      [{mod8, _}] = Code.compile_string(@migrate8)
      Yacto.Migration.Migrator.migrate(:yacto, repo0, Yacto.MigrationTest.Coin, mod8)

      # ちゃんとマイグレーションフィールドに書き込まれてるか確認する
      actual_fields =
        Yacto.Migration.SchemaMigration
        |> Ecto.Query.where(app: "yacto")
        |> Ecto.Query.select([:schema, :version])
        |> Ecto.Query.order_by([:schema, :version])
        |> repo0.all()
        |> Enum.map(fn x -> {x.schema, x.version} end)

      expected_fields = [
        {"Elixir.Yacto.MigrationTest.Coin", 0},
        {"Elixir.Yacto.MigrationTest.DecimalOption", 0},
        {"Elixir.Yacto.MigrationTest.Item", 0},
        {"Elixir.Yacto.MigrationTest.ManyIndex", 0},
        {"Elixir.Yacto.MigrationTest.Player", 0},
        {"Elixir.Yacto.MigrationTest.Player", 1},
        {"Elixir.Yacto.MigrationTest.Player", 2},
        {"Elixir.Yacto.MigrationTest.Player", 3}
      ]

      assert expected_fields == actual_fields
    end
  end
end
