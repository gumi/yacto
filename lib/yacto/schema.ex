defmodule Yacto.Schema do
  @moduledoc """
  Yacto 用のスキーマ

  以下のように利用する。

  ```
  defmodule MyApp.Schema.Item do
    use Yacto.Schema, dbname: :default

    schema @auto_source do
      field :name, :string, meta: [null: false, size: 16, index: true]
    end
  end

  defmodule MyApp.Schema.Player do
    use Yacto.Schema, dbname: :player

    schema @auto_source do
      field :name, :string, meta: [null: false, size: 16, index: true]
    end
  end
  ```
  """

  @callback dbname() :: atom

  defmacro __using__(opts) do
    dbname = Keyword.get(opts, :dbname)
    migration = Keyword.get(opts, :migration, true)
    base_schema = Keyword.get(opts, :as)

    quote do
      @behaviour Yacto.Schema

      @base_schema unquote(base_schema) || __MODULE__

      @auto_source @base_schema
                   |> Macro.underscore()
                   |> String.replace("_", "")
                   |> String.replace("/", "_")

      import Yacto.Schema, only: [schema: 2]

      @primary_key nil
      @primary_key_meta %{}
      @timestamps_opts []
      @foreign_key_type :id
      @schema_prefix nil

      # internal uses
      @yacto_orig_source nil
      @yacto_orig_calls []
      @yacto_attrs %{}
      @yacto_indices %{}
      @yacto_types %{}

      def __base_schema__() do
        @base_schema
      end

      def gen_migration? do
        unquote(migration)
      end

      if unquote(dbname) != nil do
        @impl Yacto.Schema
        def dbname() do
          unquote(dbname)
        end

        # for backward compatibility
        defoverridable dbname: 0
      end
    end
  end

  defmacro schema(source, do: block) do
    quote do
      import Yacto.Schema
      unquote(block)

      for {name, meta} <- @primary_key_meta do
        for {key, value} <- meta, key in [:size, :default] do
          new_value = Map.put(Map.get(@yacto_attrs, name, %{}), key, value)
          @yacto_attrs Map.put(@yacto_attrs, name, new_value)
        end

        for {key, value} <- meta, key == :type do
          @yacto_types Map.put(@yacto_types, name, value)
        end
      end

      @yacto_primary_key @primary_key
      @yacto_timestamps_opts @timestamps_opts
      @yacto_foreign_key_type @foreign_key_type
      @yacto_schema_prefix @schema_prefix

      use Ecto.Schema

      @primary_key @yacto_primary_key
      @timestamps_opts @yacto_timestamps_opts
      @foreign_key_type @yacto_foreign_key_type
      @schema_prefix @yacto_schema_prefix

      yacto_orig_calls = Enum.reverse(@yacto_orig_calls)

      Ecto.Schema.schema unquote(source) do
        for {m, f, a} <- yacto_orig_calls do
          Code.eval_quoted(quote(do: unquote(m).unquote(f)(unquote_splicing(a))), [], __ENV__)
        end
      end

      def __meta__(:attrs) do
        @yacto_attrs
      end

      def __meta__(:indices) do
        @yacto_indices
      end

      def __meta__(:types) do
        @yacto_types
      end
    end
  end

  defmacro field(name, type \\ :string, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      {meta, opts} = Keyword.pop(opts, :meta, [])

      meta =
        if Keyword.has_key?(opts, :default) and not Keyword.has_key?(meta, :default) do
          {:ok, default} = Ecto.Type.dump(type, opts[:default])
          Keyword.put(meta, :default, default)
        else
          meta
        end

      if not Keyword.get(opts, :virtual, false) do
        for {key, value} <- meta, key in [:null, :size, :default, :precision, :scale] do
          new_value = Map.put(Map.get(@yacto_attrs, name, %{}), key, value)
          @yacto_attrs Map.put(@yacto_attrs, name, new_value)
        end

        for {key, value} <- meta, key == :index do
          @yacto_indices Map.put(@yacto_indices, {[name], []}, value)
        end

        for {key, value} <- meta, key == :type do
          @yacto_types Map.put(@yacto_types, name, value)
        end
      end

      @yacto_orig_calls [{Ecto.Schema, :field, [name, type, opts]} | @yacto_orig_calls]
    end
  end

  defmacro index(field_or_fields, opts \\ []) do
    fields = List.wrap(field_or_fields)

    quote do
      @yacto_indices Map.put(@yacto_indices, {unquote(fields), unquote(opts)}, true)
    end
  end

  defmacro timestamps(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      default_opts = [
        inserted_at: :inserted_at,
        updated_at: :updated_at,
        type: :naive_datetime,
        usec: true
      ]

      opts = default_opts |> Keyword.merge(@timestamps_opts) |> Keyword.merge(opts)
      {meta, opts} = Keyword.pop(opts, :meta, [])

      fields = [opts[:inserted_at], opts[:updated_at]] |> Enum.filter(&(&1 != nil))

      for name <- fields do
        for {key, value} <- meta, key in [:null, :size, :default] do
          new_value = Map.put(Map.get(@yacto_attrs, name, %{}), key, value)
          @yacto_attrs Map.put(@yacto_attrs, name, new_value)
        end

        for {key, value} <- meta, key == :index do
          @yacto_indices Map.put(@yacto_indices, {[name], []}, value)
        end

        for {key, value} <- meta, key == :type do
          @yacto_types Map.put(@yacto_types, name, value)
        end
      end

      @yacto_orig_calls [
        {Ecto.Schema, :timestamps, [Enum.map(opts, &Macro.escape/1)]} | @yacto_orig_calls
      ]
    end
  end
end
