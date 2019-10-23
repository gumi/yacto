defmodule Yacto.Schema.Shard do
  @moduledoc """
  水平分割されたスキーマ

  `Yacto.Schema` とほぼ同じだが、`Yacto.DB.repo(MySchema.dbname(), shard_key: shard_key)` のショートハンドとして `MySchema.repo(shard_key: shard_key)` が使える点のみが異なる。
  """

  defmacro __using__(opts) do
    dbname = Keyword.fetch!(opts, :dbname)

    quote do
      use Yacto.Schema, dbname: unquote(dbname)

      @deprecated "Use Yacto.DB.repo/{1-2} instead"
      def repo(shard_key, opts \\ []) do
        Yacto.DB.repo(dbname(), opts)
      end
    end
  end
end
