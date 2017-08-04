defmodule Yacto.Migration.StructureTest do
  use PowerAssert

  defmodule Schema do
    use Yacto.Migration.Schema

    schema @auto_source do
    end
  end

  defmodule Test do
    defstruct []
  end

  test "inspect" do
    structure = Yacto.Migration.Structure.from_schema(Schema)
    assert "%Yacto.Migration.Structure{source: \"yacto_migration_structure_test_schema\"}" == inspect structure
    assert "%Yacto.Migration.Structure{source: \"yacto_migration_structure_test_schema\"}" == Yacto.Migration.Structure.to_string structure
  end
end
