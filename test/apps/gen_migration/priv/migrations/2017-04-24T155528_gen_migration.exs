defmodule GenMigration.Migration20170424155528 do
  use Ecto.Migration

  def change(GenMigration.Coin) do
    create table("genmigration_coin", primary_key: false) do
      add(:id, :id)
    end
    alter table("genmigration_coin") do
      modify(:id, :bigserial, [primary_key: true])
      add(:inserted_at, :naive_datetime, [])
      add(:platform, :text, [null: false])
      add(:player_id, :string, [null: false])
      add(:quantity, :integer, [default: 0, null: false])
      add(:type_id, :integer, [null: false])
      add(:updated_at, :naive_datetime, [])
    end
    create index("genmigration_coin", [:player_id, :type_id, :platform], [name: "player_id_t_65380c9f", unique: true])
  end
  def change(GenMigration.Item) do
    create table("genmigration_item", primary_key: false) do
      add(:id, :id)
    end
    alter table("genmigration_item") do
      add(:_gen_migration_dummy, :integer, [])
      remove(:id)
    end
    alter table("genmigration_item") do
      remove(:_gen_migration_dummy)
      add(:id, :binary_id, [primary_key: true])
      add(:name, :string, [])
    end
  end
  def change(GenMigration.ManyIndex) do
    create table("genmigration_manyindex", primary_key: false) do
      add(:id, :id)
    end
    alter table("genmigration_manyindex") do
      add(:aaaaaa, :string, [])
      add(:bbbbbb, :string, [])
      add(:cccccc, :string, [])
      add(:dddddd, :string, [])
      modify(:id, :bigserial, [primary_key: true])
    end
    create index("genmigration_manyindex", [:aaaaaa, :bbbbbb, :cccccc, :dddddd], [name: "aaaaaa_bbbb_9a4e1a2f"])
  end
  def change(GenMigration.Player) do
    create table("player", primary_key: false) do
      add(:id, :id)
    end
    alter table("player") do
      modify(:id, :bigserial, [primary_key: true])
      add(:inserted_at, :naive_datetime, [])
      add(:name, :string, [])
      add(:updated_at, :naive_datetime, [])
      add(:value, :integer, [])
    end
  end
  def change(GenMigration.Player2) do
    create table("player2", primary_key: false) do
      add(:id, :id)
    end
    alter table("player2") do
      modify(:id, :bigserial, [primary_key: true])
      add(:name2, :string, [])
      add(:value, :string, [])
    end
  end
  def change(GenMigration.Player3) do
    create table("genmigration_player3", primary_key: false) do
      add(:id, :id)
    end
    alter table("genmigration_player3") do
      modify(:id, :bigserial, [primary_key: true])
      add(:name3, :string, [null: false, size: 100])
      add(:value, :string, [])
    end
    create index("genmigration_player3", [:name3, :value], [name: "name3_value_index", unique: true])
    create index("genmigration_player3", [:value, :name3], [name: "value_name3_index"])
  end
  def change(GenMigration.Player4) do
    create table("genmigration_player4", primary_key: false) do
      add(:id, :id)
    end
    alter table("genmigration_player4") do
      add(:_gen_migration_dummy, :integer, [])
      remove(:id)
    end
    alter table("genmigration_player4") do
      remove(:_gen_migration_dummy)
      add(:id, :binary_id, [primary_key: true])
      add(:name3, :string, [null: false, size: 100])
      add(:value, :string, [])
    end
    create index("genmigration_player4", [:name3, :value], [name: "name3_value_index", unique: true])
    create index("genmigration_player4", [:value, :name3], [name: "value_name3_index"])
  end

  def change(_other) do
    :ok
  end

  def __migration_structures__() do
    [
      {GenMigration.Coin, %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :id}, field_sources: %{id: :id, inserted_at: :inserted_at, platform: :platform, player_id: :player_id, quantity: :quantity, type_id: :type_id, updated_at: :updated_at}, fields: [:id, :player_id, :type_id, :platform, :quantity, :inserted_at, :updated_at], meta: %{attrs: %{platform: %{null: false}, player_id: %{null: false}, quantity: %{default: 0, null: false}, type_id: %{null: false}}, indices: %{{[:player_id, :type_id, :platform], [unique: true]} => true}}, primary_key: [:id], source: "genmigration_coin", types: %{id: :id, inserted_at: :naive_datetime, platform: :text, player_id: :string, quantity: :integer, type_id: :integer, updated_at: :naive_datetime}}},
      {GenMigration.Item, %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :binary_id}, field_sources: %{id: :id, name: :name}, fields: [:id, :name], primary_key: [:id], source: "genmigration_item", types: %{id: :binary_id, name: :string}}},
      {GenMigration.ManyIndex, %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :id}, field_sources: %{aaaaaa: :aaaaaa, bbbbbb: :bbbbbb, cccccc: :cccccc, dddddd: :dddddd, id: :id}, fields: [:id, :aaaaaa, :bbbbbb, :cccccc, :dddddd], meta: %{attrs: %{}, indices: %{{[:aaaaaa, :bbbbbb, :cccccc, :dddddd], []} => true}}, primary_key: [:id], source: "genmigration_manyindex", types: %{aaaaaa: :string, bbbbbb: :string, cccccc: :string, dddddd: :string, id: :id}}},
      {GenMigration.Player, %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :id}, field_sources: %{id: :id, inserted_at: :inserted_at, name: :name, updated_at: :updated_at, value: :value}, fields: [:id, :name, :value, :inserted_at, :updated_at], primary_key: [:id], source: "player", types: %{id: :id, inserted_at: :naive_datetime, name: :string, updated_at: :naive_datetime, value: :integer}}},
      {GenMigration.Player2, %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :id}, field_sources: %{id: :id, name2: :name2, value: :value}, fields: [:id, :name2, :value], primary_key: [:id], source: "player2", types: %{id: :id, name2: :string, value: :string}}},
      {GenMigration.Player3, %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :id}, field_sources: %{id: :id, name3: :name3, value: :value}, fields: [:id, :name3, :value], meta: %{attrs: %{name3: %{null: false, size: 100}}, indices: %{{[:name3, :value], [unique: true]} => true, {[:value, :name3], []} => true}}, primary_key: [:id], source: "genmigration_player3", types: %{id: :id, name3: :string, value: :string}}},
      {GenMigration.Player4, %Yacto.Migration.Structure{autogenerate_id: {:id, :id, :binary_id}, field_sources: %{id: :id, name3: :name3, value: :value}, fields: [:id, :name3, :value], meta: %{attrs: %{name3: %{null: false, size: 100}}, indices: %{{[:name3, :value], [unique: true]} => true, {[:value, :name3], []} => true}}, primary_key: [:id], source: "genmigration_player4", types: %{id: :binary_id, name3: :string, value: :string}}},
    ]
  end

  def __migration_version__() do
    20170424155528
  end

  def __migration_preview_version__() do
    nil
  end
end
