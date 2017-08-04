defmodule Yacto.Migration.Schema do
  defmacro __using__(opts) do
    block = quote do
              @auto_source __MODULE__ |> Macro.underscore() |> String.replace("/", "_")

              import Yacto.Migration.Schema, only: [schema_meta: 1]

              # internal uses
              @yacto_migration_nulls %{}
              @yacto_migration_indices %{}
            end

    if Keyword.get(opts, :unuse_ecto_schema, false) do
      block
    else
      quote do
        use Ecto.Schema
        unquote(block)
      end
    end
  end

  defmacro schema_meta([do: block]) do
    quote do
      try do
        import Yacto.Migration.Schema
        unquote(block)
      after
        :ok
      end

      def __meta__(:nulls) do
        @yacto_migration_nulls
      end

      def __meta__(:indices) do
        @yacto_migration_indices
      end
    end
  end

  defmacro field(name, opts \\ []) do
    quote do
      opts = unquote(opts)
      name = unquote(name)
      for {key, value} <- opts, key == :null do
        @yacto_migration_nulls Map.put(@yacto_migration_nulls, name, value)
      end

      for {key, value} <- opts, key == :index do
        @yacto_migration_indices Map.put(@yacto_migration_indices, {[name], []}, value)
      end
    end
  end

  defmacro index(field_or_fields, opts \\ []) do
    fields = List.wrap(field_or_fields)
    quote do
      @yacto_migration_indices Map.put(@yacto_migration_indices, {unquote(fields), unquote(opts)}, true)
    end
  end
end
