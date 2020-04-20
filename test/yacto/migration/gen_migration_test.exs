defmodule Yacto.Migration.GenMigrationTest do
  use PowerAssert

  require Ecto.Query

  @migrate1 """
  defmodule Yacto.GenMigrationTest.Player.Migration0000 do
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
  defmodule Yacto.GenMigrationTest.Player.Migration0001 do
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
  defmodule Yacto.GenMigrationTest.Player.Migration0002 do
    use Ecto.Migration

    def change() do
      rename table("player2"), to: table("yacto_genmigrationtest_player3")
      alter table("yacto_genmigrationtest_player3") do
        remove(:name2)
        add(:name3, :string, [null: false, size: 100])
      end
      create index("yacto_genmigrationtest_player3", [:name3, :value], [name: "name3_value_index", unique: true])
      create index("yacto_genmigrationtest_player3", [:value, :name3], [name: "value_name3_index"])
      :ok
    end

    def __migration__(:structure) do
      %Yacto.Migration.Structure{field_sources: %{id: :id, name3: :name3, value: :value}, fields: [:id, :name3, :value], meta: %{attrs: %{name3: %{null: false, size: 100}}, indices: %{{[:name3, :value], [unique: true]} => true, {[:value, :name3], []} => true}}, source: "yacto_genmigrationtest_player3", types: %{id: :id, name3: :string, value: :string}}
    end

    def __migration__(:version) do
      2
    end
  end
  """

  @migrate4 """
  defmodule Yacto.GenMigrationTest.Player.Migration0003 do
    use Ecto.Migration

    def change() do
      drop table("yacto_genmigrationtest_player3")
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
    {:created, migrate1, 0} = Yacto.Migration.GenMigration.generate(Yacto.GenMigrationTest.Player, nil)
    assert @migrate1 == migrate1

    [{mod1, _}] = Code.compile_string(migrate1)
    {:changed, migrate2, 1} = Yacto.Migration.GenMigration.generate(Yacto.GenMigrationTest.Player2, mod1)
    assert @migrate2 == migrate2

    [{mod2, _}] = Code.compile_string(migrate2)
    {:changed, migrate3, 2} = Yacto.Migration.GenMigration.generate(Yacto.GenMigrationTest.Player3, mod2)
    assert @migrate3 == migrate3

    [{mod3, _}] = Code.compile_string(migrate3)
    {:deleted, migrate4, 3} = Yacto.Migration.GenMigration.generate(nil, mod3)
    assert @migrate4 == migrate4
  end

  @migrate5 """
  defmodule Yacto.GenMigrationTest.Item.Migration0000 do
    use Ecto.Migration

    def change() do
      create table("yacto_genmigrationtest_item")
      alter table("yacto_genmigrationtest_item") do
        add(:_gen_migration_dummy, :integer, [])
        remove(:id)
      end
      alter table("yacto_genmigrationtest_item") do
        remove(:_gen_migration_dummy)
        add(:id, :binary_id, [primary_key: true, autogenerate: true])
        add(:name, :string, [])
      end
      :ok
    end

    def __migration__(:structure) do
      %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :binary_id}, field_sources: %{id: :id, name: :name}, fields: [:id, :name], source: "yacto_genmigrationtest_item", types: %{id: :binary_id, name: :string}}
    end

    def __migration__(:version) do
      0
    end
  end
  """

  test "Yacto.Migration.GenMigration.generate でダミー要素が追加されるパターン" do
    {:created, migrate, 0} = Yacto.Migration.GenMigration.generate(Yacto.GenMigrationTest.Item, nil)
    assert @migrate5 == migrate
  end

  @migrate6 """
  defmodule Yacto.GenMigrationTest.ManyIndex.Migration0000 do
    use Ecto.Migration

    def change() do
      create table("yacto_genmigrationtest_manyindex")
      alter table("yacto_genmigrationtest_manyindex") do
        add(:aaaaaa, :string, [])
        add(:bbbbbb, :string, [])
        add(:cccccc, :string, [])
        add(:dddddd, :string, [])
      end
      create index("yacto_genmigrationtest_manyindex", [:aaaaaa, :bbbbbb, :cccccc, :dddddd], [name: "aaaaaa_bbbb_9a4e1a2f"])
      :ok
    end

    def __migration__(:structure) do
      %Yacto.Migration.Structure{field_sources: %{aaaaaa: :aaaaaa, bbbbbb: :bbbbbb, cccccc: :cccccc, dddddd: :dddddd, id: :id}, fields: [:id, :aaaaaa, :bbbbbb, :cccccc, :dddddd], meta: %{attrs: %{}, indices: %{{[:aaaaaa, :bbbbbb, :cccccc, :dddddd], []} => true}}, source: "yacto_genmigrationtest_manyindex", types: %{aaaaaa: :string, bbbbbb: :string, cccccc: :string, dddddd: :string, id: :id}}
    end

    def __migration__(:version) do
      0
    end
  end
  """

  test ":index_name_max_length を設定すると長いインデックス名は shrink される" do
    {:created, migrate, 0} = Yacto.Migration.GenMigration.generate(Yacto.GenMigrationTest.ManyIndex, nil, index_name_max_length: 20)
    assert @migrate6 == migrate
  end

  @migrate7 """
  defmodule Yacto.GenMigrationTest.DecimalOption.Migration0000 do
    use Ecto.Migration

    def change() do
      create table("yacto_genmigrationtest_decimaloption")
      alter table("yacto_genmigrationtest_decimaloption") do
        add(:player_id, :string, [])
        add(:decimal_field, :decimal, [precision: 7, scale: 3])
        add(:name, :string, [null: true])
      end
      :ok
    end

    def __migration__(:structure) do
      %Yacto.Migration.Structure{field_sources: %{decimal_field: :decimal_field, id: :id, name: :name, player_id: :player_id}, fields: [:id, :player_id, :decimal_field, :name], meta: %{attrs: %{decimal_field: %{precision: 7, scale: 3}, name: %{null: true}}, indices: %{}}, source: "yacto_genmigrationtest_decimaloption", types: %{decimal_field: :decimal, id: :id, name: :string, player_id: :string}}
    end

    def __migration__(:version) do
      0
    end
  end
  """

  test "decimal 型のオプションを付けてマイグレーションファイルが作れるか確認する" do
    {:created, migrate, 0} = Yacto.Migration.GenMigration.generate(Yacto.GenMigrationTest.DecimalOption, nil)
    assert @migrate7 == migrate
  end

  @migrate8 """
  defmodule Yacto.GenMigrationTest.Coin.Migration0000 do
    use Ecto.Migration

    def change() do
      create table("yacto_genmigrationtest_coin")
      alter table("yacto_genmigrationtest_coin") do
        add(:player_id, :string, [null: false])
        add(:type_id, :integer, [null: false])
        add(:platform, :text, [null: false])
        add(:quantity, :integer, [default: 0, null: false])
        add(:inserted_at, :naive_datetime, [])
        add(:updated_at, :naive_datetime, [])
      end
      create index("yacto_genmigrationtest_coin", [:player_id, :type_id, :platform], [name: "player_id_type_id_platform_index", unique: true])
      :ok
    end

    def __migration__(:structure) do
      %Yacto.Migration.Structure{field_sources: %{id: :id, inserted_at: :inserted_at, platform: :platform, player_id: :player_id, quantity: :quantity, type_id: :type_id, updated_at: :updated_at}, fields: [:id, :player_id, :type_id, :platform, :quantity, :inserted_at, :updated_at], meta: %{attrs: %{platform: %{null: false}, player_id: %{null: false}, quantity: %{default: 0, null: false}, type_id: %{null: false}}, indices: %{{[:player_id, :type_id, :platform], [unique: true]} => true}}, source: "yacto_genmigrationtest_coin", types: %{id: :id, inserted_at: :naive_datetime, platform: :text, player_id: :string, quantity: :integer, type_id: :integer, updated_at: :naive_datetime}}
    end

    def __migration__(:version) do
      0
    end
  end
  """

  test "Ecto.Type で定義したカスタム型フィールドのマイグレーションファイルを作れるか確認する" do
    {:created, migrate, 0} = Yacto.Migration.GenMigration.generate(Yacto.GenMigrationTest.Coin, nil)
    assert @migrate8 == migrate
  end

  test "生成したマイグレーションファイルで実際にマイグレートできるか確認する" do
    repo0_config = [
      database: "migrator_repo0",
      username: "root",
      password: "",
      hostname: "localhost",
      port: 3306
    ]

    for {repo, config} <- [
          {Yacto.MigratorTest.Repo0, repo0_config}
        ] do
      _ = repo.__adapter__.storage_down(config)
      :ok = repo.__adapter__.storage_up(config)
    end

    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.MigratorTest.Repo0, repo0_config})

    Yacto.Migration.SchemaMigration.ensure_schema_migrations_table!(Yacto.MigratorTest.Repo0)

    [{mod1, _}] = Code.compile_string(@migrate1)
    Yacto.Migration.Migrator.migrate(:yacto, Yacto.MigratorTest.Repo0, Yacto.GenMigrationTest.Player, mod1)
    [{mod2, _}] = Code.compile_string(@migrate2)
    Yacto.Migration.Migrator.migrate(:yacto, Yacto.MigratorTest.Repo0, Yacto.GenMigrationTest.Player, mod2)
    [{mod3, _}] = Code.compile_string(@migrate3)
    Yacto.Migration.Migrator.migrate(:yacto, Yacto.MigratorTest.Repo0, Yacto.GenMigrationTest.Player, mod3)
    [{mod4, _}] = Code.compile_string(@migrate4)
    Yacto.Migration.Migrator.migrate(:yacto, Yacto.MigratorTest.Repo0, Yacto.GenMigrationTest.Player, mod4)

    [{mod5, _}] = Code.compile_string(@migrate5)
    Yacto.Migration.Migrator.migrate(:yacto, Yacto.MigratorTest.Repo0, Yacto.GenMigrationTest.Item, mod5)

    [{mod6, _}] = Code.compile_string(@migrate6)
    Yacto.Migration.Migrator.migrate(:yacto, Yacto.MigratorTest.Repo0, Yacto.GenMigrationTest.ManyIndex, mod6)

    [{mod7, _}] = Code.compile_string(@migrate7)
    Yacto.Migration.Migrator.migrate(:yacto, Yacto.MigratorTest.Repo0, Yacto.GenMigrationTest.DecimalOption, mod7)

    [{mod8, _}] = Code.compile_string(@migrate8)
    Yacto.Migration.Migrator.migrate(:yacto, Yacto.MigratorTest.Repo0, Yacto.GenMigrationTest.Coin, mod8)

    # ちゃんとマイグレーションフィールドに書き込まれてるか確認する
    actual_fields =
      Yacto.Migration.SchemaMigration
      |> Ecto.Query.where(app: "yacto")
      |> Ecto.Query.select([:schema, :version])
      |> Ecto.Query.order_by([:schema, :version])
      |> Yacto.MigratorTest.Repo0.all()
      |> Enum.map(fn x -> {x.schema, x.version} end)
    expected_fields = [
      {"Elixir.Yacto.GenMigrationTest.DecimalOption", 0},
      {"Elixir.Yacto.GenMigrationTest.Item", 0},
      {"Elixir.Yacto.GenMigrationTest.ManyIndex", 0},
      {"Elixir.Yacto.GenMigrationTest.Player", 0},
      {"Elixir.Yacto.GenMigrationTest.Player", 1},
      {"Elixir.Yacto.GenMigrationTest.Player", 2},
      {"Elixir.Yacto.GenMigrationTest.Player", 3}
    ]
    assert expected_fields == actual_fields
  end
end
