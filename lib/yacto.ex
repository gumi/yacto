defmodule Yacto do
  @external_resource "README.md"
  @moduledoc File.read!("README.md")
             |> String.split(~r/<!-- MDOC !-->/)
             |> Enum.fetch!(1)

  def transaction(databases, fun, opts \\ []) do
    dbopts = Keyword.get(opts, :databases)

    f = fn
      {dbname, dbkey} -> Yacto.DB.repo(dbname, shard_key: dbkey, databases: dbopts)
      dbname -> Yacto.DB.repo(dbname, databases: dbopts)
    end

    repos = Enum.map(databases, f)
    Yacto.XA.transaction(repos, fun, opts)
  end
end
