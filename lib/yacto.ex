defmodule Yacto do
  @moduledoc """
  #{File.read!("README.md")}
  """

  def transaction(databases, fun, opts \\ []) do
    f = fn
      {dbname, dbkey} -> Yacto.DB.repo(dbname, dbkey)
      dbname -> Yacto.DB.repo(dbname)
    end

    repos = Enum.map(databases, f)
    Yacto.XA.transaction(repos, fun, opts)
  end
end
