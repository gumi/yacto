defmodule Yacto.Schema.Shard do
  @moduledoc """
  Horizontal partitioned schema
  """

  defmacro __using__(opts) do
    dbname = Keyword.fetch!(opts, :dbname)

    {:ok, db} = Access.fetch(Application.fetch_env!(:yacto, :databases), dbname)

    if db.module != Yacto.DB.Shard do
      raise "Database type of #{dbname} that is a database name used by the module #{__MODULE__} is not Yacto.DB.Shard."
    end

    quote do
      use Yacto.Schema, dbname: unquote(dbname)

      # TODO: remove Yacto 2.0
      @primary_key {:id, :binary_id, autogenerate: true}

      def repo(shard_key) do
        Yacto.DB.repo(dbname(), shard_key)
      end
    end
  end
end
