defmodule CustomTableNameTest do
  use PowerAssert

  @migrate """
  defmodule CustomTableName.Migration20170424155528 do
    use Ecto.Migration

    def change(CustomTableName.Player.Schema.TestData) do
      create table("custom_table_name_player")
      alter table("custom_table_name_player") do
        add(:name, :string, [default: "hage", null: false, size: 100])
        add(:text_data, :text, [null: false])
        add(:value, :string, [])
      end
      create index("custom_table_name_player", [:name, :value], [name: "name_value_index", unique: true])
      create index("custom_table_name_player", [:value, :name], [name: "value_name_index"])
    end

    def change(_other) do
      :ok
    end

    def __migration_structures__() do
      [
        {CustomTableName.Player.Schema.TestData, %Yacto.Migration.Structure{field_sources: %{id: :id, name: :name, text: :text_data, value: :value}, fields: [:id, :name, :value, :text], meta: %{attrs: %{name: %{default: "hage", null: false, size: 100}, text: %{null: false}}, indices: %{{[:name, :value], [unique: true]} => true, {[:value, :name], []} => true}}, source: "custom_table_name_player", types: %{id: :id, name: :string, text: :text, value: :string}}},
      ]
    end

    def __migration_version__() do
      20170424155528
    end
  end
  """

  test "Yacto.Migration.GenMigration generate_source with custom table name." do
    v1 = [
      {CustomTableName.Player.Schema.TestData, %Yacto.Migration.Structure{},
       Yacto.Migration.Structure.from_schema(CustomTableName.Player.Schema.TestData)}
    ]

    source = Yacto.Migration.GenMigration.generate_source(CustomTableName, v1, 20_170_424_155_528)
    assert @migrate == source
  end
end
