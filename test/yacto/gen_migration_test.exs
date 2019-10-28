defmodule Yacto.GenMigrationTest do
  use PowerAssert

  test "Yacto.Migration.Structure.diff" do
    structure_from = %Yacto.Migration.Structure{
      fields: [:id, :name, :value],
      field_sources: %{id: :id, name: :name, value: :value},
      source: "player",
      types: %{id: :id, name: :string, value: :integer}
    }

    structure_to = %Yacto.Migration.Structure{
      autogenerate_id: {:id2, :id2, :binary_id},
      fields: [:id, :name2, :value],
      field_sources: %{id: :id, name2: :name2, value: :value},
      primary_key: [:id2],
      source: "player",
      types: %{id: :id, name2: :string, value: :string}
    }

    diff = Yacto.Migration.Structure.diff(structure_from, structure_to)

    assert %{
             source: :not_changed,
             fields: [eq: [:id], del: [:name], ins: [:name2], eq: [:value]],
             types: %{
               del: %{name: :string, value: :integer},
               ins: %{name2: :string, value: :string}
             },
             primary_key: [del: [:id], ins: [:id2]],
             autogenerate_id: {:changed, {:id, :id, :id}, {:id2, :id2, :binary_id}},
             meta: %{attrs: %{del: %{}, ins: %{}}, indices: %{del: %{}, ins: %{}}}
           } == diff
  end

  @migrate1 """
  defmodule Yacto.GenMigrationTest.Migration20170424155528 do
    use Ecto.Migration

    def change(Yacto.GenMigrationTest.Player) do
      create table("player")
      alter table("player") do
        add(:name, :string, [])
        add(:value, :integer, [])
        add(:inserted_at, :naive_datetime, [])
        add(:updated_at, :naive_datetime, [])
      end
    end

    def change(_other) do
      :ok
    end

    def __migration_structures__() do
      [
        {Yacto.GenMigrationTest.Player, %Yacto.Migration.Structure{field_sources: %{id: :id, inserted_at: :inserted_at, name: :name, updated_at: :updated_at, value: :value}, fields: [:id, :name, :value, :inserted_at, :updated_at], source: "player", types: %{id: :id, inserted_at: :naive_datetime, name: :string, updated_at: :naive_datetime, value: :integer}}},
      ]
    end

    def __migration_version__() do
      20170424155528
    end

    def __migration_preview_version__() do
      nil
    end
  end
  """

  @migrate2 """
  defmodule Yacto.GenMigrationTest.Migration20170424155530 do
    use Ecto.Migration

    def change(Yacto.GenMigrationTest.Player) do
      rename table("player"), to: table("player2")
      alter table("player2") do
        remove(:inserted_at)
        remove(:name)
        remove(:updated_at)
        remove(:value)
        add(:name2, :string, [])
        add(:value, :string, [])
      end
    end

    def change(_other) do
      :ok
    end

    def __migration_structures__() do
      [
        {Yacto.GenMigrationTest.Player, %Yacto.Migration.Structure{field_sources: %{id: :id, name2: :name2, value: :value}, fields: [:id, :name2, :value], source: "player2", types: %{id: :id, name2: :string, value: :string}}},
      ]
    end

    def __migration_version__() do
      20170424155530
    end

    def __migration_preview_version__() do
      20170424155528
    end
  end
  """

  @migrate3 """
  defmodule Yacto.GenMigrationTest.Migration20170424155532 do
    use Ecto.Migration

    def change(Yacto.GenMigrationTest.Player) do
      rename table("player2"), to: table("yacto_genmigrationtest_player3")
      alter table("yacto_genmigrationtest_player3") do
        remove(:name2)
        add(:name3, :string, [null: false, size: 100])
      end
      create index("yacto_genmigrationtest_player3", [:name3, :value], [name: "name3_value_index", unique: true])
      create index("yacto_genmigrationtest_player3", [:value, :name3], [name: "value_name3_index"])
    end

    def change(_other) do
      :ok
    end

    def __migration_structures__() do
      [
        {Yacto.GenMigrationTest.Player, %Yacto.Migration.Structure{field_sources: %{id: :id, name3: :name3, value: :value}, fields: [:id, :name3, :value], meta: %{attrs: %{name3: %{null: false, size: 100}}, indices: %{{[:name3, :value], [unique: true]} => true, {[:value, :name3], []} => true}}, source: "yacto_genmigrationtest_player3", types: %{id: :id, name3: :string, value: :string}}},
      ]
    end

    def __migration_version__() do
      20170424155532
    end

    def __migration_preview_version__() do
      20170424155530
    end
  end
  """

  @migrate4 """
  defmodule Yacto.GenMigrationTest.Migration20170424155533 do
    use Ecto.Migration

    def change(Yacto.GenMigrationTest.Player) do
      drop table("yacto_genmigrationtest_player3")
    end

    def change(_other) do
      :ok
    end

    def __migration_structures__() do
      [
        {Yacto.GenMigrationTest.Player, %Yacto.Migration.Structure{}},
      ]
    end

    def __migration_version__() do
      20170424155533
    end

    def __migration_preview_version__() do
      20170424155532
    end
  end
  """

  test "Yacto.Migration.GenMigration.generate_source" do
    v1 = [
      {Yacto.GenMigrationTest.Player, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player)}
    ]

    v2 = [
      {Yacto.GenMigrationTest.Player,
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player),
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player2)}
    ]

    v3 = [
      {Yacto.GenMigrationTest.Player,
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player2),
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player3)}
    ]

    v4 = [
      {Yacto.GenMigrationTest.Player,
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Player3),
       %Yacto.Migration.Structure{}}
    ]

    source =
      Yacto.Migration.GenMigration.generate_source(
        Yacto.GenMigrationTest,
        v1,
        20_170_424_155_528,
        nil
      )

    assert @migrate1 == source

    source =
      Yacto.Migration.GenMigration.generate_source(
        Yacto.GenMigrationTest,
        v2,
        20_170_424_155_530,
        20_170_424_155_528
      )

    assert @migrate2 == source

    source =
      Yacto.Migration.GenMigration.generate_source(
        Yacto.GenMigrationTest,
        v3,
        20_170_424_155_532,
        20_170_424_155_530
      )

    assert @migrate3 == source

    source =
      Yacto.Migration.GenMigration.generate_source(
        Yacto.GenMigrationTest,
        v4,
        20_170_424_155_533,
        20_170_424_155_532
      )

    assert @migrate4 == source
  end

  @migrate5 """
  defmodule Yacto.GenMigrationTest.Migration20170424155528 do
    use Ecto.Migration

    def change(Yacto.GenMigrationTest.Item) do
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
    end

    def change(_other) do
      :ok
    end

    def __migration_structures__() do
      [
        {Yacto.GenMigrationTest.Item, %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :binary_id}, field_sources: %{id: :id, name: :name}, fields: [:id, :name], source: "yacto_genmigrationtest_item", types: %{id: :binary_id, name: :string}}},
      ]
    end

    def __migration_version__() do
      20170424155528
    end

    def __migration_preview_version__() do
      nil
    end
  end
  """

  test "Yacto.Migration.GenMigration generate_source with dummy." do
    v1 = [
      {Yacto.GenMigrationTest.Item, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.Item)}
    ]

    source =
      Yacto.Migration.GenMigration.generate_source(
        Yacto.GenMigrationTest,
        v1,
        20_170_424_155_528,
        nil
      )

    assert @migrate5 == source
  end

  @migrate6 """
  defmodule Yacto.GenMigrationTest.Migration20170424155528 do
    use Ecto.Migration

    def change(Yacto.GenMigrationTest.ManyIndex) do
      create table("yacto_genmigrationtest_manyindex")
      alter table("yacto_genmigrationtest_manyindex") do
        add(:aaaaaa, :string, [])
        add(:bbbbbb, :string, [])
        add(:cccccc, :string, [])
        add(:dddddd, :string, [])
      end
      create index("yacto_genmigrationtest_manyindex", [:aaaaaa, :bbbbbb, :cccccc, :dddddd], [name: "aaaaaa_bbbb_9a4e1a2f"])
    end

    def change(_other) do
      :ok
    end

    def __migration_structures__() do
      [
        {Yacto.GenMigrationTest.ManyIndex, %Yacto.Migration.Structure{field_sources: %{aaaaaa: :aaaaaa, bbbbbb: :bbbbbb, cccccc: :cccccc, dddddd: :dddddd, id: :id}, fields: [:id, :aaaaaa, :bbbbbb, :cccccc, :dddddd], meta: %{attrs: %{}, indices: %{{[:aaaaaa, :bbbbbb, :cccccc, :dddddd], []} => true}}, source: "yacto_genmigrationtest_manyindex", types: %{aaaaaa: :string, bbbbbb: :string, cccccc: :string, dddddd: :string, id: :id}}},
      ]
    end

    def __migration_version__() do
      20170424155528
    end

    def __migration_preview_version__() do
      nil
    end
  end
  """

  test "Shrink long index name" do
    v1 = [
      {Yacto.GenMigrationTest.ManyIndex, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.ManyIndex)}
    ]

    source =
      Yacto.Migration.GenMigration.generate_source(
        Yacto.GenMigrationTest,
        v1,
        20_170_424_155_528,
        nil,
        index_name_max_length: 20
      )

    assert @migrate6 == source
  end

  @migrate7 """
  defmodule Yacto.GenMigrationTest.Migration20190401125611 do
    use Ecto.Migration

    def change(Yacto.GenMigrationTest.DecimalOption) do
      create table("yacto_genmigrationtest_decimaloption")
      alter table("yacto_genmigrationtest_decimaloption") do
        add(:player_id, :string, [])
        add(:decimal_field, :decimal, [precision: 7, scale: 3])
        add(:name, :string, [null: true])
      end
    end

    def change(_other) do
      :ok
    end

    def __migration_structures__() do
      [
        {Yacto.GenMigrationTest.DecimalOption, %Yacto.Migration.Structure{field_sources: %{decimal_field: :decimal_field, id: :id, name: :name, player_id: :player_id}, fields: [:id, :player_id, :decimal_field, :name], meta: %{attrs: %{decimal_field: %{precision: 7, scale: 3}, name: %{null: true}}, indices: %{}}, source: "yacto_genmigrationtest_decimaloption", types: %{decimal_field: :decimal, id: :id, name: :string, player_id: :string}}},
      ]
    end

    def __migration_version__() do
      20190401125611
    end

    def __migration_preview_version__() do
      nil
    end
  end
  """

  test "Yacto.Migration.GenMigration decimal field option." do
    v1 = [
      {Yacto.GenMigrationTest.DecimalOption, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(Yacto.GenMigrationTest.DecimalOption)}
    ]

    source =
      Yacto.Migration.GenMigration.generate_source(
        Yacto.GenMigrationTest,
        v1,
        20_190_401_125_611,
        nil
      )

    assert @migrate7 == source
  end
end
