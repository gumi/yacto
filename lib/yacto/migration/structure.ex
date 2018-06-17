defmodule Yacto.Migration.Structure do
  defstruct source: nil,
            prefix: nil,
            primary_key: [:id],
            fields: [:id],
            field_sources: %{id: :id},
            types: %{id: :id},
            associations: [],
            embeds: [],
            read_after_writes: [],
            autogenerate_id: {:id, :id, :id},
            meta: %{attrs: %{}, indices: %{}}

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
    deletes =
      for {key, value} <- difference, key == :del do
        value
      end

    deletes = deletes |> Enum.concat() |> Enum.into(%{})

    # get all :ins
    inserts =
      for {key, value} <- difference, key == :ins do
        value
      end

    inserts = inserts |> Enum.concat() |> Enum.into(%{})

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
    source = once_difference(structure_from.source, structure_to.source)
    from_fields = Enum.map(structure_from.fields, &structure_from.field_sources[&1])
    to_fields = Enum.map(structure_to.fields, &structure_to.field_sources[&1])
    fields = List.myers_difference(from_fields, to_fields)
    primary_key = List.myers_difference(structure_from.primary_key, structure_to.primary_key)

    autogenerate_id =
      once_difference(structure_from.autogenerate_id, structure_to.autogenerate_id)

    from_types =
      structure_from.types
      |> Enum.map(fn {f, t} -> {Map.fetch!(structure_from.field_sources, f), t} end)
      |> Enum.into(%{})

    to_types =
      structure_to.types
      |> Enum.map(fn {f, t} -> {Map.fetch!(structure_to.field_sources, f), t} end)
      |> Enum.into(%{})

    types = map_difference(from_types, to_types)

    from_attrs =
      structure_from.meta.attrs
      |> Enum.map(fn {f, t} -> {Map.fetch!(structure_from.field_sources, f), t} end)
      |> Enum.into(%{})

    to_attrs =
      structure_to.meta.attrs
      |> Enum.map(fn {f, t} -> {Map.fetch!(structure_to.field_sources, f), t} end)
      |> Enum.into(%{})

    from_indices =
      structure_from.meta.indices
      |> Enum.map(fn {{fields, opts}, value} ->
        {{Enum.map(fields, &Map.fetch!(structure_from.field_sources, &1)), opts}, value}
      end)
      |> Enum.into(%{})

    to_indices =
      structure_to.meta.indices
      |> Enum.map(fn {{fields, opts}, value} ->
        {{Enum.map(fields, &Map.fetch!(structure_to.field_sources, &1)), opts}, value}
      end)
      |> Enum.into(%{})

    meta = %{
      attrs: map_difference(from_attrs, to_attrs),
      indices: map_difference(from_indices, to_indices)
    }

    %{
      source: source,
      fields: fields,
      primary_key: primary_key,
      autogenerate_id: autogenerate_id,
      types: types,
      meta: meta
    }
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

    source = apply_once_difference(structure_to.source, patch.source)

    alias Yacto.Migration.Util
    primary_key = Util.apply_myers_difference(structure_to.primary_key, patch.primary_key)
    autogenerate_id = apply_once_difference(structure_to.autogenerate_id, patch.autogenerate_id)
    fields = Util.apply_myers_difference(structure_to.fields, patch.fields)
    types = apply_map_difference(structure_to.types, patch.types)
    meta_attrs = apply_map_difference(structure_to.meta.attrs, patch.meta.attrs)
    meta_indices = apply_map_difference(structure_to.meta.indices, patch.meta.indices)

    structure_to = %{structure_to | source: source}
    structure_to = %{structure_to | primary_key: primary_key}
    structure_to = %{structure_to | autogenerate_id: autogenerate_id}
    structure_to = %{structure_to | fields: fields}
    structure_to = %{structure_to | types: types}
    structure_to = put_in(structure_to.meta.attrs, meta_attrs)
    structure_to = put_in(structure_to.meta.indices, meta_indices)
    structure_to
  end

  def from_schema(schema) do
    keys =
      struct(__MODULE__) |> Map.drop([:__struct__, :meta, :types, :field_sources]) |> Map.keys()

    fields = keys |> Enum.map(fn key -> {key, schema.__schema__(key)} end)
    # get types
    types =
      for field <- schema.__schema__(:fields), into: %{} do
        # use specified migration type if :type is defined in meta
        result =
          if function_exported?(schema, :__meta__, 1) do
            types = schema.__meta__(:types)
            Map.fetch(types, field)
          else
            :error
          end

        type =
          case result do
            :error ->
              # resolve ecto type if :type is not defined
              type = schema.__schema__(:type, field)
              type = Ecto.Type.type(type)
              type

            {:ok, type} ->
              type
          end

        {field, type}
      end

    fields = [{:types, types} | fields]

    # get field_sources
    field_sources =
      for field <- schema.__schema__(:fields), into: %{} do
        {field, schema.__schema__(:field_source, field)}
      end

    fields = [{:field_sources, field_sources} | fields]

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
    drop_keys =
      for {k, v} <- Map.to_list(value), v == Map.fetch!(default, k) do
        k
      end

    value = Map.drop(value, drop_keys)
    Inspect.Map.inspect(value, Inspect.Atom.inspect(Yacto.Migration.Structure, opts), opts)
  end
end
