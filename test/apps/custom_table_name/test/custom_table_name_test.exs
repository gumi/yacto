defmodule CustomTableNameTest do
  use PowerAssert

  @migrate """
  defmodule CustomTableName.Migration20170424155528 do
    use Ecto.Migration

    def change(CustomTableName.Player.Schema.TestData) do
      create table("custom_table_name_player")
      alter table("custom_table_name_player") do
        add(:name, :string, [default: "hoge", null: false, size: 100])
      end
    end

    def change(_other) do
      :ok
    end

    def __migration_structures__() do
      [
        {CustomTableName.Player.Schema.TestData, %Yacto.Migration.Structure{field_sources: %{id: :id, name: :name}, fields: [:id, :name], meta: %{attrs: %{name: %{default: "hoge", null: false, size: 100}}, indices: %{}}, source: "custom_table_name_player", types: %{id: :id, name: :string}}},
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
