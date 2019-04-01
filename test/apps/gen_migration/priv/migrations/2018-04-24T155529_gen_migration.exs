defmodule GenMigration.Migration20180424155529 do
  use Ecto.Migration

  def change(GenMigration.DecimalOption) do
    create table("genmigration_decimaloption")
    alter table("genmigration_decimaloption") do
      add(:decimal_field, :decimal, [precision: 7, scale: 3])
      add(:name, :string, [null: true])
      add(:player_id, :string, [])
    end
  end
  def change(GenMigration.Player2) do
    create table("player2")
    alter table("player2") do
      add(:name2, :string, [])
      add(:value, :string, [])
    end
  end
  def change(GenMigration.Player3) do
    create table("genmigration_player3")
    alter table("genmigration_player3") do
      add(:name3, :string, [null: false, size: 100])
      add(:value, :string, [])
    end
    create index("genmigration_player3", [:name3, :value], [name: "name3_value_index", unique: true])
    create index("genmigration_player3", [:value, :name3], [name: "value_name3_index"])
  end
  def change(GenMigration.PlayerUnknown) do
    drop table("player")
  end

  def change(_other) do
    :ok
  end

  def __migration_structures__() do
    [
      {GenMigration.Coin, %Yacto.Migration.Structure{field_sources: %{id: :id, inserted_at: :inserted_at, platform: :platform, player_id: :player_id, quantity: :quantity, type_id: :type_id, updated_at: :updated_at}, fields: [:id, :player_id, :type_id, :platform, :quantity, :inserted_at, :updated_at], meta: %{attrs: %{platform: %{null: false}, player_id: %{null: false}, quantity: %{default: 0, null: false}, type_id: %{null: false}}, indices: %{{[:player_id, :type_id, :platform], [unique: true]} => true}}, source: "genmigration_coin", types: %{id: :id, inserted_at: :naive_datetime, platform: :text, player_id: :string, quantity: :integer, type_id: :integer, updated_at: :naive_datetime}}},
      {GenMigration.DecimalOption, %Yacto.Migration.Structure{field_sources: %{decimal_field: :decimal_field, id: :id, name: :name, player_id: :player_id}, fields: [:id, :player_id, :decimal_field, :name], meta: %{attrs: %{decimal_field: %{precision: 7, scale: 3}, name: %{null: true}}, indices: %{}}, source: "genmigration_decimaloption", types: %{decimal_field: :decimal, id: :id, name: :string, player_id: :string}}},
      {GenMigration.Item, %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :binary_id}, field_sources: %{id: :id, name: :name}, fields: [:id, :name], source: "genmigration_item", types: %{id: :binary_id, name: :string}}},
      {GenMigration.ManyIndex, %Yacto.Migration.Structure{field_sources: %{aaaaaa: :aaaaaa, bbbbbb: :bbbbbb, cccccc: :cccccc, dddddd: :dddddd, id: :id}, fields: [:id, :aaaaaa, :bbbbbb, :cccccc, :dddddd], meta: %{attrs: %{}, indices: %{{[:aaaaaa, :bbbbbb, :cccccc, :dddddd], []} => true}}, source: "genmigration_manyindex", types: %{aaaaaa: :string, bbbbbb: :string, cccccc: :string, dddddd: :string, id: :id}}},
      {GenMigration.Player, %Yacto.Migration.Structure{field_sources: %{id: :id, inserted_at: :inserted_at, name: :name, updated_at: :updated_at, value: :value}, fields: [:id, :name, :value, :inserted_at, :updated_at], source: "player", types: %{id: :id, inserted_at: :naive_datetime, name: :string, updated_at: :naive_datetime, value: :integer}}},
      {GenMigration.Player2, %Yacto.Migration.Structure{field_sources: %{id: :id, name2: :name2, value: :value}, fields: [:id, :name2, :value], source: "player2", types: %{id: :id, name2: :string, value: :string}}},
      {GenMigration.Player3, %Yacto.Migration.Structure{field_sources: %{id: :id, name3: :name3, value: :value}, fields: [:id, :name3, :value], meta: %{attrs: %{name3: %{null: false, size: 100}}, indices: %{{[:name3, :value], [unique: true]} => true, {[:value, :name3], []} => true}}, source: "genmigration_player3", types: %{id: :id, name3: :string, value: :string}}},
      {GenMigration.PlayerUnknown, %Yacto.Migration.Structure{}},
    ]
  end

  def __migration_version__() do
    20180424155529
  end

  def __migration_preview_version__() do
    20180424155528
  end
end
