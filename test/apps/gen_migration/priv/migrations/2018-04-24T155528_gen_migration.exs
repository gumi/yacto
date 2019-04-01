defmodule GenMigration.Migration20180424155528 do
  use Ecto.Migration

  def change(GenMigration.Coin) do
    create table("genmigration_coin")
    alter table("genmigration_coin") do
      add(:inserted_at, :naive_datetime, [])
      add(:platform, :text, [null: false])
      add(:player_id, :string, [null: false])
      add(:quantity, :integer, [default: 0, null: false])
      add(:type_id, :integer, [null: false])
      add(:updated_at, :naive_datetime, [])
    end
    create index("genmigration_coin", [:player_id, :type_id, :platform], [name: "player_id_type_id_platform_index", unique: true])
  end
  def change(GenMigration.Item) do
    create table("genmigration_item")
    alter table("genmigration_item") do
      add(:_gen_migration_dummy, :integer, [])
      remove(:id)
    end
    alter table("genmigration_item") do
      remove(:_gen_migration_dummy)
      add(:id, :binary_id, [primary_key: true, autogenerate: true])
      add(:name, :string, [])
    end
  end
  def change(GenMigration.ManyIndex) do
    create table("genmigration_manyindex")
    alter table("genmigration_manyindex") do
      add(:aaaaaa, :string, [])
      add(:bbbbbb, :string, [])
      add(:cccccc, :string, [])
      add(:dddddd, :string, [])
    end
    create index("genmigration_manyindex", [:aaaaaa, :bbbbbb, :cccccc, :dddddd], [name: "aaaaaa_bbbbbb_cccccc_dddddd_index"])
  end
  def change(GenMigration.Player) do
    create table("player")
    alter table("player") do
      add(:inserted_at, :naive_datetime, [])
      add(:name, :string, [])
      add(:updated_at, :naive_datetime, [])
      add(:value, :integer, [])
    end
  end
  def change(GenMigration.PlayerUnknown) do
    create table("player")
    alter table("player") do
      add(:inserted_at, :naive_datetime, [])
      add(:name, :string, [])
      add(:updated_at, :naive_datetime, [])
      add(:value, :integer, [])
    end
  end

  def change(_other) do
    :ok
  end

  def __migration_structures__() do
    [
      {GenMigration.Coin, %Yacto.Migration.Structure{field_sources: %{id: :id, inserted_at: :inserted_at, platform: :platform, player_id: :player_id, quantity: :quantity, type_id: :type_id, updated_at: :updated_at}, fields: [:id, :player_id, :type_id, :platform, :quantity, :inserted_at, :updated_at], meta: %{attrs: %{platform: %{null: false}, player_id: %{null: false}, quantity: %{default: 0, null: false}, type_id: %{null: false}}, indices: %{{[:player_id, :type_id, :platform], [unique: true]} => true}}, source: "genmigration_coin", types: %{id: :id, inserted_at: :naive_datetime, platform: :text, player_id: :string, quantity: :integer, type_id: :integer, updated_at: :naive_datetime}}},
      {GenMigration.Item, %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :binary_id}, field_sources: %{id: :id, name: :name}, fields: [:id, :name], source: "genmigration_item", types: %{id: :binary_id, name: :string}}},
      {GenMigration.ManyIndex, %Yacto.Migration.Structure{field_sources: %{aaaaaa: :aaaaaa, bbbbbb: :bbbbbb, cccccc: :cccccc, dddddd: :dddddd, id: :id}, fields: [:id, :aaaaaa, :bbbbbb, :cccccc, :dddddd], meta: %{attrs: %{}, indices: %{{[:aaaaaa, :bbbbbb, :cccccc, :dddddd], []} => true}}, source: "genmigration_manyindex", types: %{aaaaaa: :string, bbbbbb: :string, cccccc: :string, dddddd: :string, id: :id}}},
      {GenMigration.Player, %Yacto.Migration.Structure{field_sources: %{id: :id, inserted_at: :inserted_at, name: :name, updated_at: :updated_at, value: :value}, fields: [:id, :name, :value, :inserted_at, :updated_at], source: "player", types: %{id: :id, inserted_at: :naive_datetime, name: :string, updated_at: :naive_datetime, value: :integer}}},
      {GenMigration.PlayerUnknown, %Yacto.Migration.Structure{field_sources: %{id: :id, inserted_at: :inserted_at, name: :name, updated_at: :updated_at, value: :value}, fields: [:id, :name, :value, :inserted_at, :updated_at], source: "player", types: %{id: :id, inserted_at: :naive_datetime, name: :string, updated_at: :naive_datetime, value: :integer}}},
    ]
  end

  def __migration_version__() do
    20180424155528
  end

  def __migration_preview_version__() do
    nil
  end
end
