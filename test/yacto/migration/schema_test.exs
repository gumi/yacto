defmodule Yacto.Migration.SchemaTest do
  use PowerAssert

  defmodule Schema do
    use Yacto.Migration.Schema

    schema @auto_source do
    end
  end

  test "use EctoSchema" do
    assert "yacto_migration_schema_test_schema" == Schema.__schema__(:source)
  end

  defmodule TestMeta do
    use Yacto.Migration.Schema

    schema @auto_source do
      field :name
      field :value, :integer
      timestamps()
    end
    schema_meta do
      field :name, null: false, index: true
      field :value, null: false

      index :value
      index [:value, :name]
      index [:name, :value], unique: true
    end
  end

  test "schema_meta" do
    assert %{name: false,
             value: false} == TestMeta.__meta__(:nulls)
    assert %{{[:name], []} => true,
             {[:value], []} => true,
             {[:value, :name], []} => true,
             {[:name, :value], [unique: true]} => true} == TestMeta.__meta__(:indices)
  end

end
