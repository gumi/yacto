defmodule Yacto.Schema.Query do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      def _get(dbkey, kwargs) do
        Yacto.Query.get(__MODULE__, Yacto.DB.repo(__MODULE__.dbname(), dbkey), kwargs)
      end

      def _get_or_new(dbkey, kwargs) do
        Yacto.Query.get_or_new(__MODULE__, Yacto.DB.repo(__MODULE__.dbname(), dbkey), kwargs)
      end
    end
  end
end
