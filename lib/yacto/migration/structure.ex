defmodule Yacto.Migration.Structure do
  defstruct [source: nil,
             prefix: nil,
             primary_key: [:id],
             fields: [:id],
             types: %{id: :id},
             associations: [],
             embeds: [],
             read_after_writes: [],
             autogenerate_id: {:id, :id, :id},
             meta: %{attrs: %{},
                     indices: %{}}]

  # undocumented keys:
  #   :query
  #   :hash
  #   :autogenerate
  #   :autoupdate

  defp once_difference(nil, nil) do
    :not_changed
  end
  defp once_difference(nil, to_value) do
    {:create, to_value}
  end
  defp once_difference(from_value, nil) do
    {:delete, from_value}
  end
  defp once_difference(from_value, to_value) do
    if from_value == to_value do
      :not_changed
    else
      {:changed, from_value, to_value}
    end
  end

  defp myers_difference_to_map(difference) do
    # get all :del
    deletes = for({key, value} <- difference, key == :del, do: value) |> Enum.concat() |> Enum.into(%{})
    # get all :ins
    inserts = for({key, value} <- difference, key == :ins, do: value) |> Enum.concat() |> Enum.into(%{})

    %{del: deletes, ins: inserts}
  end

  defp map_difference(from_map, to_map) do
    from_map = from_map |> Map.to_list() |> Enum.sort()
    to_map = to_map |> Map.to_list() |> Enum.sort()
    difference = List.myers_difference(from_map, to_map)
    myers_difference_to_map(difference)
  end

  def diff(structure_from, structure_to) do
    # %Yacto.Migration.Structure{
    #   associations: [],
    #   autogenerate_id: {:id, :id, :id},
    #   embeds: [],
    #   fields: [:id, :name, :value],
    #   prefix: nil,
    #   primary_key: [:id],
    #   read_after_writes: [],
    #   source: "player",
    #   types: %{id: :id, name: :string, value: :integer}
    # }
    %{source: once_difference(structure_from.source, structure_to.source),
      fields: List.myers_difference(structure_from.fields, structure_to.fields),
      primary_key: List.myers_difference(structure_from.primary_key, structure_to.primary_key),
      autogenerate_id: once_difference(structure_from.autogenerate_id, structure_to.autogenerate_id),
      types: map_difference(structure_from.types, structure_to.types),
      meta: %{attrs: map_difference(structure_from.meta.attrs, structure_to.meta.attrs),
              indices: map_difference(structure_from.meta.indices, structure_to.meta.indices)}}
  end

  defp apply_map_difference(value, map_diff) do
    value = Map.drop(value, map_diff.del |> Enum.map(fn {k, _} -> k end))
    value = Map.merge(value, map_diff.ins)
    value
  end

  defp apply_once_difference(value, diff) do
    case diff do
      :not_changed -> value
      {:changed, _from_value, to_value} -> to_value
    end
  end

  # patch = diff(structure_from, structure_to)
  # assert structure_to == apply(structure_from, patch)
  def apply(structure_from, patch) do
    structure_to = structure_from
    structure_to = %{structure_to | source: apply_once_difference(structure_to.source, patch.source)}
    structure_to = %{structure_to | primary_key: Yacto.Migration.Util.apply_myers_difference(structure_to.primary_key, patch.primary_key)}
    structure_to = %{structure_to | autogenerate_id: apply_once_difference(structure_to.autogenerate_id, patch.autogenerate_id)}
    structure_to = %{structure_to | fields: Yacto.Migration.Util.apply_myers_difference(structure_to.fields, patch.fields)}
    structure_to = %{structure_to | types: apply_map_difference(structure_to.types, patch.types)}
    structure_to = put_in(structure_to.meta.attrs, apply_map_difference(structure_to.meta.attrs, patch.meta.attrs))
    structure_to = put_in(structure_to.meta.indices, apply_map_difference(structure_to.meta.indices, patch.meta.indices))
    structure_to
  end

  def from_schema(schema) do
    keys = struct(__MODULE__) |> Map.drop([:__struct__, :meta, :types]) |> Map.keys()
    fields = keys |> Enum.map(fn key -> {key, schema.__schema__(key)} end)
    # get types
    types = for field <- schema.__schema__(:fields), into: %{} do
              type = schema.__schema__(:type, field)
              type = Ecto.Type.type(type)
              {field, type}
            end
    fields = [{:types, types} | fields]

    st = struct(__MODULE__, fields)
    if function_exported?(schema, :__meta__, 1) do
      meta_keys = Map.keys(struct(__MODULE__).meta)
      metas = meta_keys |> Enum.map(fn key -> {key, schema.__meta__(key)} end) |> Enum.into(%{})
      Map.put(st, :meta, metas)
    else
      st
    end
  end

  def to_string(value) do
    value
    |> Inspect.Yacto.Migration.Structure.inspect(%Inspect.Opts{})
    |> Inspect.Algebra.format(:infinity)
    |> IO.iodata_to_binary()
  end
end

defimpl Inspect, for: Yacto.Migration.Structure do
  def inspect(value, opts) do
    default = %Yacto.Migration.Structure{}
    # remove default value
    drop_keys = for {k, v} <- Map.to_list(value), v == Map.fetch!(default, k) do
                  k
                end
    value = Map.drop(value, drop_keys)
    Inspect.Map.inspect(value, Inspect.Atom.inspect(Yacto.Migration.Structure, opts), opts)
  end
end
