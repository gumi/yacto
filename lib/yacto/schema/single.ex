defmodule Yacto.Schema.Single do
  @moduledoc """
  通常の（水平分割されていない）スキーマ

  `Yacto.Schema` とほぼ同じだが、`Yacto.DB.repo(MySchema.dbname())` のショートハンドとして `MySchema.repo()` が使える点のみが異なる。
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
