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

    Enum.into(xs, %{})
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

      def __migration_preview_version__() do
        <%= inspect @preview_version %>
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

  @doc """
  最新のマイグレーションモジュールを取得する

  マイグレーションモジュールが１件も存在しなかった場合は `nil` を返す。
  """
  def get_latest_migration(migration_dir \\ nil) do
    dir = Yacto.Migration.Util.get_migration_dir_for_gen(migration_dir)
    paths = Path.wildcard(Path.join(dir, '*.exs'))

    mods =
      paths
      |> Enum.map(&extract_modules/1)
      |> List.flatten()

    Enum.max_by(mods, & &1.__migration_version__(), fn -> nil end)
  end

  @doc """
  マイグレーションファイルを生成する

  - app: 対象のアプリケーション
  - schemas: このアプリケーションに存在するスキーマの一覧
  - delete_schemas: このアプリケーションから削除されたスキーマの一覧
  - migration_version: 生成するマイグレーションファイルのバージョン。nil の場合はタイムスタンプから自動生成される。
  - migration_dir: マイグレーションファイルを出力するディレクトリ
  - opts: オプション
    - `:index_name_max_length`: インデックス名の最大長。
      自動的に生成されたインデックス名がこの長さを超えてしまう場合、ハッシュ化した名前に変換される。
      `:infinity` の場合、決してハッシュ化を行わない。デフォルトは `:infinity`。
  """
  def generate_migration(
        app,
        schemas,
        delete_schemas \\ [],
        migration_version \\ nil,
        migration_dir \\ nil,
        opts \\ []
      ) do
    if migration_version != nil do
      Yacto.Migration.Util.validate_version(migration_version)
    end

    migration = get_latest_migration(migration_dir)

    structures =
      if migration != nil do
        migration.__migration_structures__()
        |> Enum.into(%{})
      else
        nil
      end

    structure_infos =
      Enum.map(schemas, fn schema ->
        from = structures[schema] || %Yacto.Migration.Structure{}
        to = Yacto.Migration.Structure.from_schema(schema)
        {schema, from, to}
      end)

    delete_structure_infos =
      Enum.map(delete_schemas, fn schema ->
        from = Map.fetch!(structures, schema)
        to = %Yacto.Migration.Structure{}
        {schema, from, to}
      end)

    structure_infos = structure_infos ++ delete_structure_infos

    migration_version = migration_version || timestamp()
    migration_preview_version = if migration, do: migration.__migration_version__(), else: nil

    app_prefix = app |> Atom.to_string() |> Macro.camelize() |> String.to_atom()

    source =
      generate_source(
        app_prefix,
        structure_infos,
        migration_version,
        migration_preview_version,
        opts
      )

    if source == :not_changed do
      Logger.info("All schemas are not changed. A migration file is not generated.")
    else
      dir = Yacto.Migration.Util.get_migration_dir_for_gen(migration_dir)
      :ok = File.mkdir_p!(dir)

      path =
        Yacto.Migration.Util.get_migration_path_for_gen(app, migration_version, migration_dir)

      File.write!(path, source)

      Logger.info("Successful! Generated a migration file: #{path}")
    end
  end

  def generate_source(
        app_prefix,
        structure_infos,
        migration_version,
        migration_preview_version,
        opts \\ []
      ) do
    structure_infos = Enum.sort(structure_infos)

    migration_name =
      app_prefix
      |> Module.concat("Migration#{migration_version}")
      |> Atom.to_string()
      |> String.replace_prefix("Elixir.", "")

    schema_infos =
      for {schema, from, to} <- structure_infos do
        case generate_lines(from, to, opts) do
          :not_changed -> :not_changed
          lines -> %{schema: schema, lines: lines}
        end
      end

    schema_infos =
      schema_infos
      |> Enum.filter(fn
        :not_changed -> false
        _ -> true
      end)

    structures =
      structure_infos
      |> Enum.map(fn {schema, _from, to} -> {schema, to} end)

    if length(schema_infos) == 0 do
      :not_changed
    else
      EEx.eval_string(
        get_template(),
        assigns: [
          migration_name: migration_name,
          schema_infos: schema_infos,
          structures: structures,
          version: migration_version,
          preview_version: migration_preview_version
        ]
      )
    end
  end

  defp generate_lines(structure_from, structure_to, migration_opts) do
    diff = Yacto.Migration.Structure.diff(structure_from, structure_to)
    rdiff = Yacto.Migration.Structure.diff(structure_to, structure_from)

    if diff == rdiff do
      :not_changed
    else
      lines =
        case diff.source do
          :not_changed ->
            []

          {:changed, from_value, to_value} ->
            ["rename table(#{inspect(from_value)}), to: table(#{inspect(to_value)})"]

          {:delete, from_value} ->
            ["drop table(#{inspect(from_value)})"]

          {:create, _to_value} ->
            ["create table(#{inspect(structure_to.source)})"]
        end

      lines =
        lines ++
          case diff.source do
            {:delete, _} ->
              []

            _ ->
              generated_fields =
                generate_fields(diff.types, diff.meta.attrs, structure_to, migration_opts)

              indices = generate_indices(diff.meta.indices, structure_to, migration_opts)

              if Enum.empty?(generated_fields) do
                indices
                |> Map.values()
                |> List.flatten()
              else
                Map.get(indices, :drop, []) ++
                  ["alter table(#{inspect(structure_to.source)}) do"] ++
                  generated_fields ++
                  ["end"] ++
                  Map.get(indices, :create, [])
              end
          end

      lines
    end
  end

  defp timestamp() do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    String.to_integer("#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}")
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
