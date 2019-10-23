defmodule Yacto.Schema.Single do
  @moduledoc """
  通常の（水平分割されていない）スキーマ

  `Yacto.Schema` とほぼ同じだが、`Yacto.DB.repo(MySchema.dbname())` のショートハンドとして `MySchema.repo()` が使える点のみが異なる。
  """

  defmacro __using__(opts) do
    dbname = Keyword.fetch!(opts, :dbname)

    quote do
      use Yacto.Schema, dbname: unquote(dbname)

      @deprecated "Use Yacto.DB.repo/{2-3} instead"
      def repo(opts \\ []) do
        Yacto.DB.repo(dbname(), opts)
      end
    end
  end
end
