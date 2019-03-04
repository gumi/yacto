defmodule Yacto.Schema.Shard do
  @moduledoc """
  水平分割されたスキーマ

  `Yacto.Schema` とほぼ同じだが、`Yacto.DB.repo(MySchema.dbname(), shard_key)` のショートハンドとして `MySchema.repo(shard_key)` が使える点のみが異なる。
  """

  defmacro __using__(opts) do
    dbname = Keyword.fetch!(opts, :dbname)

    {:ok, db} = Access.fetch(Application.fetch_env!(:yacto, :databases), dbname)

    if db.module != Yacto.DB.Shard do
      raise "Database type of #{dbname} that is a database name used by the module #{__MODULE__} is not Yacto.DB.Shard."
    end

    quote do
      use Yacto.Schema, dbname: unquote(dbname)

      def repo(shard_key) do
        Yacto.DB.repo(dbname(), shard_key)
      end
    end
  end
end
