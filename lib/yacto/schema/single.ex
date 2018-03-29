defmodule Yacto.Schema.Single do
  @moduledoc """
  Normal (non horizontal partitioned) schema
  """

  defmacro __using__(opts) do
    dbname = Keyword.fetch!(opts, :dbname)

    {:ok, db} = Access.fetch(Application.fetch_env!(:yacto, :databases), dbname)

    if db.module != Yacto.DB.Single do
      raise "Database type of #{dbname} that is a database name used by the module #{__MODULE__} is not Yacto.DB.Single."
    end

    quote do
      use Yacto.Schema, dbname: unquote(dbname)

      def repo() do
        Yacto.DB.repo(dbname())
      end
    end
  end
end
