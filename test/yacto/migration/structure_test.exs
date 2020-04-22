defmodule Yacto.Migration.StructureTest do
  use PowerAssert

  defmodule Schema do
    use Yacto.Schema, dbname: :default

    schema @auto_source do
    end
  end

  test "inspect した時にデフォルト値の要素は出力されない" do
    structure = Yacto.Migration.Structure.from_schema(Schema)

    assert "%Yacto.Migration.Structure{source: \"yacto_migration_structuretest_schema\"}" ==
             inspect(structure)

    assert "%Yacto.Migration.Structure{source: \"yacto_migration_structuretest_schema\"}" ==
             Yacto.Migration.Structure.to_string(structure)
  end

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
end
