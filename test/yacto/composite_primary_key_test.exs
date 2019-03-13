defmodule Yacto.CompositePrimaryKeyTest do
  use PowerAssert
  defmodule Parent1 do
    use Ecto.Schema

    schema "parents" do
      field :name, :string
      field :player_id, :string
      field :foo, :string
    end
  end

  defmodule Parent2 do
    use Ecto.Schema
    @primary_key false

    schema "parents" do
      field :name, :string
      field :player_id, :string, primary_key: true
      field :foo, :string, primary_key: true
    end
  end


  test "composite primary key" do

    #    p = %Parent{name: "foo", player_id: "bar", foo: "baz"}
    #    IO.inspect Parent.__schema__(:primary_key)

    s1 = Yacto.Migration.Structure.from_schema(Parent1)
    s2 = Yacto.Migration.Structure.from_schema(Parent2)
    Yacto.Migration.Structure.diff(s1, s2)
    |> IO.inspect

    #  %{
    #  autogenerate_id: {:delete, {:id, :id, :id}},
    #  fields: [del: [:id], eq: [:name, :player_id, :foo]],
    #  meta: %{attrs: %{del: %{}, ins: %{}}, indices: %{del: %{}, ins: %{}}},
    #  primary_key: [del: [:id], ins: [:player_id, :foo]],
    #  source: :not_changed,
    #  types: %{del: %{id: :id}, ins: %{}}
    #}


  end

end

