defmodule Yacto.Shard.Repo do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @repos Keyword.fetch!(opts, :repos)

      def __repos__() do
        @repos
      end

      def shard(shard_key) do
        Enum.fetch!(@repos, :erlang.phash2(shard_key, length(@repos)))
      end
    end
  end
end
