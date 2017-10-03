defmodule Yacto.SchemaTest do
  use PowerAssert

  defmodule User do
    use Yacto.Schema

    def dbname(), do: :default

    schema @auto_source do
      field :name, :string
      timestamps()
    end

    def changeset do
      # If the structure is defined with __before_compile__/1, this code will not be compiled
      Ecto.Changeset.change(%__MODULE__{}, [])
    end
  end
end
