defmodule Yacto.Migration.SchemaTest do
  use PowerAssert

  defmodule Schema do
    use Yacto.Schema, dbname: :default

    schema @auto_source do
    end
  end

  test "use EctoSchema" do
    assert "yacto_migration_schematest_schema" == Schema.__schema__(:source)
  end

  defmodule TestMeta do
    use Yacto.Schema, dbname: :dbname

    @primary_key {:id, :string, autogenerate: {UUID, :uuid4, []}}
    @primary_key_meta %{id: [size: 64]}

    schema @auto_source do
      field(:name, :string, meta: [null: false, size: 50, default: "foo", index: true])
      field(:value, :integer, meta: [null: false])
      timestamps()

      index(:value)
      index([:value, :name])
      index([:name, :value], unique: true)
    end
  end

  test "schema_meta" do
    expected = %{
      id: %{size: 64},
      name: %{null: false, size: 50, default: "foo"},
      value: %{null: false}
    }

    assert expected == TestMeta.__meta__(:attrs)

    assert %{
             {[:name], []} => true,
             {[:value], []} => true,
             {[:value, :name], []} => true,
             {[:name, :value], [unique: true]} => true
           } == TestMeta.__meta__(:indices)
  end
end
