defmodule Yacto.Migration.GenMigration do
  require Logger

  defp generate_table(source) do
    case source do
      :not_changed -> []
      {:changed, from_value, to_value} -> ["rename table(String.to_atom(#{inspect from_value})), to: table(String.to_atom(#{inspect to_value}))"]
      {:delete, from_value} -> ["drop table(String.to_atom(#{inspect from_value}))"]
      {:create, to_value} -> ["create table(String.to_atom(#{inspect to_value}))"]
    end
  end

  def generate_fields(types, structure_to) do
    del = for {key, _type} <- types.del do
            "alter table(String.to_atom(#{inspect structure_to.source})), do: remove(:#{key})"
          end
    ins = for {key, type} <- types.ins do
            opts = []
            opts = opts ++ if(Enum.find(structure_to.primary_key, &(&1 == key)) != nil, do: [primary_key: true], else: [])
            opts = opts ++ if(elem(structure_to.autogenerate_id, 0) == key, do: [autogenerate: true], else: [])
            "alter table(String.to_atom(#{inspect structure_to.source})), do: add(:#{key}, :#{type}, #{inspect opts})"
          end

    if Enum.find(types.del, fn {key, _type} -> key == :id end) != nil do
      dummy1 = ["alter table(String.to_atom(#{inspect structure_to.source})), do: add(:_gen_migration_dummy, :integer, [])"]
      dummy2 = ["alter table(String.to_atom(#{inspect structure_to.source})), do: remove(:_gen_migration_dummy)"]
      dummy1 ++ del ++ ins ++ dummy2
    else
      del ++ ins
    end
  end

  def generate_attrs(attrs, structure_to) do
    xs = for {changetype, changes} <- attrs do
           case changetype do
             :del ->
               for {field, _value} <- changes do
                 # modify to default
                 type = Map.fetch!(structure_to.types, field)
                 "alter table(String.to_atom(#{inspect structure_to.source})), do: modify(:#{field}, :#{type})"
               end
             :ins ->
               for {field, value} <- changes do
                 keyword = Map.to_list(value)
                 type = Map.fetch!(structure_to.types, field)
                 "alter table(String.to_atom(#{inspect structure_to.source})), do: modify(:#{field}, :#{type}, #{inspect keyword})"
               end
           end
         end
    List.flatten(xs)
  end

  def generate_indices(indices, structure_to) do
    xs = for {changetype, changes} <- indices do
           case changetype do
             :del ->
               for {{fields, opts}, value} <- changes, value do
                 "drop index(String.to_atom(#{inspect structure_to.source}), #{inspect fields}, #{inspect opts})"
               end
             :ins ->
               for {{fields, opts}, value} <- changes, value do
                 "create index(String.to_atom(#{inspect structure_to.source}), #{inspect fields}, #{inspect opts})"
               end
           end
         end
    List.flatten(xs)
  end

  def generate_sizes(sizes, structure_to) do
    xs = for {changetype, changes} <- sizes do
           case changetype do
             :del ->
               for {field, _value} <- changes do
                 type = Map.fetch!(structure_to.types, field)
                 "alter table(String.to_atom(#{inspect structure_to.source})), do: modify(:#{field}, :#{type}, size: 255)"
               end
             :ins ->
               for {field, value} <- changes do
                 type = Map.fetch!(structure_to.types, field)
                 "alter table(String.to_atom(#{inspect structure_to.source})), do: modify(:#{field}, :#{type}, size: #{value})"
               end
           end
         end
    List.flatten(xs)
  end

  defp get_template() do
    """
    defmodule <%= @migration_name %> do
      use Ecto.Migration
<%= for schema_info <- @schema_infos do %>
      def change(<%= schema_info.schema |> Atom.to_string() |> String.replace_prefix("Elixir.", "") %>) do<%= for line <- schema_info.lines do %>
        <%= line %><% end %>
      end<% end %>

      def change(_other) do
        :ok
      end

      def __migration_structures__() do
        [<%= for {schema, structure} <- @structures do %>
          {<%= inspect schema %>, <%= Yacto.Migration.Structure.to_string structure %>},<% end %>
        ]
      end

      def __migration_version__() do
        <%= inspect @version %>
      end
    end
    """
  end

  defp extract_modules(file) do
    modules = Code.load_file(file)
    for {mod, _bin} <- modules, function_exported?(mod, :__migration_structures__, 0) do
      mod
    end
  end

  def get_latest_migration(migration_dir \\ nil) do
    dir = Yacto.Migration.Util.get_migration_dir_for_gen(migration_dir)
    paths = Path.wildcard(Path.join(dir, '*.exs'))
    mods = paths
           |> Enum.map(&extract_modules/1)
           |> List.flatten()
    Enum.max_by(mods, &(&1.__migration_version__()), fn -> nil end)
  end

  def generate_migration(app, schemas, delete_schemas \\ [], migration_version \\ nil, migration_dir \\ nil) do
    if migration_version != nil do
      Yacto.Migration.Util.validate_version(migration_version)
    end

    migration = get_latest_migration(migration_dir)
    structures = if migration != nil do
                   migration.__migration_structures__()
                   |> Enum.into(%{})
                 else
                   nil
                 end
    structure_infos = Enum.map(schemas,
                               fn schema ->
                                 from = structures[schema] || %Yacto.Migration.Structure{}
                                 to = Yacto.Migration.Structure.from_schema(schema)
                                 {schema, from, to}
                               end)
    delete_structure_infos = Enum.map(delete_schemas,
                                      fn schema ->
                                        from = Map.fetch!(structures, schema)
                                        to = %Yacto.Migration.Structure{}
                                        {schema, from, to}
                                      end)
    structure_infos = structure_infos ++ delete_structure_infos

    migration_version = migration_version || timestamp()

    app_prefix = app |> Atom.to_string() |> Macro.camelize() |> String.to_atom()
    source = generate_source(app_prefix, structure_infos, migration_version)
    if source == :not_changed do
      Logger.info "All schemas are not changed. A migration file is not generated."
    else
      dir = Yacto.Migration.Util.get_migration_dir_for_gen(migration_dir)
      :ok = File.mkdir_p!(dir)

      path = Yacto.Migration.Util.get_migration_path_for_gen(app, migration_version, migration_dir)
      File.write!(path, source)

      Logger.info "Successful! Generated a migration file: #{path}"
    end
  end

  def generate_source(app_prefix, structure_infos, migration_version) do
    structure_infos = Enum.sort(structure_infos)

    migration_name = app_prefix
                     |> Module.concat("Migration#{migration_version}")
                     |> Atom.to_string()
                     |> String.replace_prefix("Elixir.", "")

    schema_infos = for {schema, from, to} <- structure_infos do
                     case generate_lines(from, to) do
                       :not_changed -> :not_changed
                        lines -> %{schema: schema,
                                   lines: lines}
                     end
                   end
    structures = structure_infos
                 |> Enum.filter(fn :not_changed -> false
                                   _ -> true end)
                 |> Enum.map(fn {schema, _from, to} -> {schema, to} end)
    if length(structures) == 0 do
      :not_changed
    else
      EEx.eval_string(get_template(), assigns: [migration_name: migration_name,
                                                schema_infos: schema_infos,
                                                structures: structures,
                                                version: migration_version])
    end
  end
  defp generate_lines(structure_from, structure_to) do
    diff = Yacto.Migration.Structure.diff(structure_from, structure_to)
    rdiff = Yacto.Migration.Structure.diff(structure_to, structure_from)
    if diff == rdiff do
      :not_changed
    else
      lines = []
      lines = lines ++ generate_table(diff.source)
      lines = case diff.source do
                {:delete, _} -> lines
                _ -> lines ++
                     generate_fields(diff.types, structure_to) ++
                     generate_attrs(diff.meta.attrs, structure_to) ++
                     generate_indices(diff.meta.indices, structure_to)
              end
      lines
    end
  end

  defp timestamp() do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    String.to_integer("#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}")
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)
end
