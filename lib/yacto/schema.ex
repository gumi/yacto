
defmodule Yacto.Schema do
  @moduledoc """
  ```
  defmodule MyApp.Schema.Item do
    use Yacto.Schema

    def repo(), do: :default

    schema @auto_source do
      field :name, :string, meta: [null: false, size: 16, index: true]
    end
  end

  defmodule MyApp.Schema.Player do
    use Yacto.Schema

    def repo(), do: :player

    schema @auto_source do
      field :name, :string, meta: [null: false, size: 16, index: true]
    end
  end
  ```
  """
  defmacro __using__(_opts) do
    quote do
      @auto_source __MODULE__ |> Macro.underscore() |> String.replace("/", "_")

      import Yacto.Schema, only: [schema: 2]

      @primary_key nil
      @timestamps_opts []
      @foreign_key_type :id
      @schema_prefix nil

      # internal uses
      @yacto_orig_source nil
      @yacto_orig_calls []
      @yacto_attrs %{}
      @yacto_indices %{}

      @before_compile Yacto.Schema
    end
  end

  defmacro schema(source, [do: block]) do
    quote do
      import Yacto.Schema
      unquote(block)

      @yacto_orig_source unquote(source)
    end
  end

  defmacro field(name, type \\ :string, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      {meta, opts} = Keyword.pop(opts, :meta, [])
      for {key, value} <- meta, key in [:null, :size] do
        new_value = Map.put(Map.get(@yacto_attrs, name, %{}), key, value)
        @yacto_attrs Map.put(@yacto_attrs, name, new_value)
      end

      for {key, value} <- meta, key == :index do
        @yacto_indices Map.put(@yacto_indices, {[name], []}, value)
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

  defmacro __before_compile__(_) do
    quote location: :keep do
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
      Ecto.Schema.schema @yacto_orig_source do
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
    end
  end
end
