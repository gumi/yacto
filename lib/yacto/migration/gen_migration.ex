defmodule Yacto.Migration.GenMigration do
  require Logger

  defp convert_fields(types, attrs) do
    # types:
    #   %{del: %{field: type},
    #     ins: %{field: type}}
    # attrs:
    #   %{ins: %{field: attr},
    #     del: %{field: attr}}
    # result:
    #   [{field, {:add, {type, attr}} |
    #            :remove |
    #            {:modify, attr}}]

    # get all field names
    type_fields =
      for {_, changes} <- types,
          {field, _} <- changes do
        field
      end

    attr_fields =
      for {_, changes} <- attrs,
          {field, _} <- changes do
        field
      end

    fields = type_fields ++ attr_fields
    fields = fields |> Enum.sort() |> Enum.dedup()

    changes =
      for field <- fields do
        in_type_del = Map.has_key?(types.del, field)
        in_type_ins = Map.has_key?(types.ins, field)

        cond do
          in_type_del && in_type_ins ->
            # :remove and :add
            type = Map.fetch!(types.ins, field)

            attr =
              if Map.has_key?(attrs.ins, field) do
                Map.to_list(Map.fetch!(attrs.ins, field))
              else
                []
              end

            [{field, :remove}, {field, {:add, type, attr}}]

          in_type_del && !in_type_ins ->
            # :remove
            [{field, :remove}]

          !in_type_del && in_type_ins ->
            # :add
            type = Map.fetch!(types.ins, field)

            attr =
              if Map.has_key?(attrs.ins, field) do
                Map.to_list(Map.fetch!(attrs.ins, field))
              else
                []
              end

            [{field, {:add, type, attr}}]

          !in_type_del && !in_type_ins ->
            # :modify
            attr =
              if Map.has_key?(attrs.ins, field) do
                Map.to_list(Map.fetch!(attrs.ins, field))
              else
                # modify to default
                []
              end

            [{field, {:modify, attr}}]
        end
      end

    List.flatten(changes)
  end

  def generate_fields(types, attrs, structure_to, _migration_opts) do
    ops = convert_fields(types, attrs)

    # ops の :add 系とそれ以外を分ける
    {add_ops, other_ops} =
      ops
      |> Enum.split_with(fn
        {_, {:add, _, _}} -> true
        _ -> false
      end)

    # add_ops の順序をフィールドの定義順に並び替える（計算量は O(N^2)）
    add_ops =
      structure_to.fields
      |> Enum.flat_map(fn field ->
        Enum.filter(add_ops, fn {opfield, _} -> structure_to.field_sources[field] == opfield end)
      end)

    ops = other_ops ++ add_ops

    lines =
      for {field, op} <- ops do
        case op do
          {:add, type, attr} ->
            opts = attr

            is_primary_key = Enum.find(structure_to.primary_key, &(&1 == field)) != nil
            opts = opts ++ if(is_primary_key, do: [primary_key: true], else: [])

            is_autogenerate =
              if(
                structure_to.autogenerate_id,
                do: elem(structure_to.autogenerate_id, 0) == field,
                else: false
              )

            opts = opts ++ if(is_autogenerate, do: [autogenerate: true], else: [])

            ["  add(:#{field}, #{inspect(type)}, #{inspect(opts)})"]

          :remove ->
            lines = ["  remove(:#{field})"]

            if field == :id do
              ["  add(:_gen_migration_dummy, :integer, [])"] ++
                lines ++
                ["end"] ++
                ["alter table(#{inspect(structure_to.source)}) do"] ++
                ["  remove(:_gen_migration_dummy)"]
            else
              lines
            end

          {:modify, attr} ->
            type = Map.fetch!(structure_to.types, field)
            ["  modify(:#{field}, :#{type}, #{inspect(attr)})"]
        end
      end

    List.flatten(lines)
  end

  defp create_index_name(fields, max_length) do
    # minimum max_length is 10
    if max_length != :infinity && max_length < 10 do
      raise "Invalid max_length: #{max_length}"
    end

    name =
      [fields, "index"]
      |> List.flatten()
      |> Enum.join("_")
      |> String.replace(~r"[^\w_]", "_")
      |> String.replace("__", "_")

    if max_length == :infinity || String.length(name) <= max_length do
      name
    else
      # shrink index name
      # long_index_name_index -> long_i_cd9351f4 when max_length == 15
      # long_index_name_index -> long_index__cd9351f4 when max_length == 20

      hash = :crypto.hash(:sha, name) |> Base.encode16(case: :lower) |> String.slice(0, 8)
      shrinked_name = String.slice(name, 0, max_length - 9)
      Enum.join([shrinked_name, "_", hash])
    end
  end

  def generate_indices(indices, structure_to, migration_opts) do
    xs =
      for {changetype, changes} <- indices do
        case changetype do
          :del ->
            {:drop,
             for {{fields, opts}, value} <- changes, value do
               opts =
                 if Keyword.has_key?(opts, :name) do
                   opts
                 else
                   [
                     {:name,
                      create_index_name(
                        fields,
                        Keyword.get(migration_opts, :index_name_max_length, :infinity)
                      )}
                     | opts
                   ]
                 end

               "drop index(#{inspect(structure_to.source)}, #{inspect(fields)}, #{inspect(opts)})"
             end}

          :ins ->
            {:create,
             for {{fields, opts}, value} <- changes, value do
               opts =
                 if Keyword.has_key?(opts, :name) do
                   opts
                 else
                   [
                     {:name,
                      create_index_name(
                        fields,
                        Keyword.get(migration_opts, :index_name_max_length, :infinity)
                      )}
                     | opts
                   ]
                 end

               "create index(#{inspect(structure_to.source)}, #{inspect(fields)}, #{inspect(opts)})"
             end}
        end
      end

    m = Enum.into(xs, %{})
    {Map.get(m, :create, []), Map.get(m, :drop, [])}
  end

  defp get_template() do
    """
    defmodule <%= @migration_name %> do
      use Ecto.Migration

      def change() do<%= for line <- @lines do %>
        <%= line %><% end %>
        :ok
      end

      def __migration__(:structure) do
        <%= Yacto.Migration.Structure.to_string @structure %>
      end

      def __migration__(:version) do
        <%= inspect @version %>
      end
    end
    """
  end

  @spec generate(nil | module(), nil | module(), Keyword.t()) ::
          :not_changed
          | {:created, String.t(), integer()}
          | {:changed, String.t(), integer()}
          | {:deleted, String.t(), integer()}
  def generate(schema, migration, opts \\ []) do
    structure_from =
      if migration == nil,
        do: %Yacto.Migration.Structure{},
        else: migration.__migration__(:structure)

    structure_to =
      if schema == nil,
        do: %Yacto.Migration.Structure{},
        else: Yacto.Migration.Structure.from_schema(schema)

    schema_name =
      if migration == nil do
        to_string(schema.__base_schema__())
      else
        # Foo.Bar.Migration0000 の Migration0000 の部分だけ削る
        migration |> Module.split() |> List.delete_at(-1) |> Module.concat() |> to_string()
      end

    result = generate_lines(structure_from, structure_to, opts)

    case result do
      :not_changed ->
        :not_changed

      {type, lines} ->
        version = if(migration == nil, do: 0, else: migration.__migration__(:version) + 1)

        str =
          EEx.eval_string(
            get_template(),
            assigns: [
              migration_name: inspect(Module.concat([schema_name, "Migration#{pad4(version)}"])),
              lines: lines,
              structure: structure_to,
              version: version
            ]
          )

        {type, str, version}
    end
  end

  # :not_changed |
  # {:created, lines} |
  # {:changed, lines} |
  # {:deleted, lines}
  defp generate_lines(structure_from, structure_to, migration_opts) do
    try do
      diff = Yacto.Migration.Structure.diff(structure_from, structure_to)
      rdiff = Yacto.Migration.Structure.diff(structure_to, structure_from)

      if diff == rdiff do
        throw(:not_changed)
      end

      db_lines =
        case diff.source do
          :not_changed ->
            []

          {:changed, from_value, to_value} ->
            ["rename table(#{inspect(from_value)}), to: table(#{inspect(to_value)})"]

          {:delete, from_value} ->
            throw({:deleted, ["drop table(#{inspect(from_value)})"]})

          {:create, _to_value} ->
            ["create table(#{inspect(structure_to.source)})"]
        end

      generated_fields =
        generate_fields(diff.types, diff.meta.attrs, structure_to, migration_opts)

      {create_indices, drop_indices} =
        generate_indices(diff.meta.indices, structure_to, migration_opts)

      field_lines =
        if Enum.empty?(generated_fields) do
          drop_indices ++ create_indices
        else
          drop_indices ++
            ["alter table(#{inspect(structure_to.source)}) do"] ++
            generated_fields ++
            ["end"] ++
            create_indices
        end

      lines = db_lines ++ field_lines

      case diff.source do
        {:create, _} -> {:created, lines}
        _ -> {:changed, lines}
      end
    catch
      :throw, result -> result
    end
  end

  # defp timestamp() do
  #  {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
  #  String.to_integer("#{y}-#{pad(m)}-#{pad(d)}-#{pad(hh)}#{pad(mm)}#{pad(ss)}")
  # end

  # defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  # defp pad(i), do: to_string(i)

  defp pad4(i) when i < 10, do: <<?0, ?0, ?0, ?0 + i>>
  defp pad4(i) when i < 100, do: <<?0, ?0, ?0 + div(i, 10), ?0 + rem(i, 10)>>

  defp pad4(i) when i < 1000,
    do: <<?0, ?0 + div(i, 100), ?0 + rem(div(i, 10), 10), ?0 + rem(i, 10)>>

  defp pad4(i), do: to_string(i)
end
