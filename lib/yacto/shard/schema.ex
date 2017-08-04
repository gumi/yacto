defmodule Yacto.Shard.Schema do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use Yacto.Migration.Schema

      @shard_repo Keyword.fetch!(opts, :shard_repo)

      def __shard_repo__() do
        @shard_repo
      end
    end
  end
end
