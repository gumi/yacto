defmodule Yacto.XA do
  defp run_multi([], fun, _opts, conns) do
    fun.(conns)
  end

  defp run_multi([repo | repos], fun, opts, conns) do
    {pool, default_opts} = repo.__pool__
    DBConnection.run(
      pool,
      fn conn ->
        try do
          Process.put(adapter_key(pool), conn)
          Process.put(xa_key(conn), true)

          run_multi(repos, fun, opts, Map.put(conns, repo, conn))
        after
          Process.delete(adapter_key(pool))
          Process.delete(xa_key(conn))
        end
      end,
      opts ++ default_opts)
  end

  defp try_and_rescue(fun, rescue_fun) do
    try do
      fun.()
    rescue
      error ->
        rescue_fun.()
        reraise(error, System.stacktrace)
    end
  end

  defmodule RepoState do
    defstruct [:repo, :uuid, :conn]
  end

  defp rollback(repo_states) do
    # rollback from any state
    repo_states
    |> Enum.each(fn repo_state ->
                   for command <- ["END", "PREPARE", "ROLLBACK"] do
                     try do
                       Ecto.Adapters.SQL.query!(repo_state.repo, "XA #{command} '#{repo_state.uuid}'", [])
                     rescue
                       _error ->
                         # ignore errors
                         :ignore
                     end
                   end
                 end)
  end

  defp commit(repo_states) do
    # commit from any state
    repo_states
    |> Enum.each(fn repo_state ->
                   for command <- ["END", "PREPARE", "COMMIT"] do
                     try do
                       Ecto.Adapters.SQL.query!(repo_state.repo, "XA #{command} '#{repo_state.uuid}'", [])
                     rescue
                       _error ->
                         # ignore errors
                         :ignore
                     end
                   end
                 end)
  end

  def with_xa(conns, repos, fun) do
    repo_states = repos
                  |> Enum.map(fn repo ->
                                %RepoState{repo: repo,
                                           uuid: UUID.uuid4(),
                                           conn: Map.fetch!(conns, repo)}
                              end)

    result = try_and_rescue(
               fn ->
                 repo_states |> Enum.each(fn %RepoState{repo: repo, uuid: uuid} -> Ecto.Adapters.SQL.query!(repo, "XA START '#{uuid}'", []) end)
                 result = fun.()
                 repo_states |> Enum.each(fn %RepoState{repo: repo, uuid: uuid} -> Ecto.Adapters.SQL.query!(repo, "XA END '#{uuid}'", []) end)
                 repo_states |> Enum.each(fn %RepoState{repo: repo, uuid: uuid} -> Ecto.Adapters.SQL.query!(repo, "XA PREPARE '#{uuid}'", []) end)
                 result
               end,
               fn -> rollback(repo_states) end)

    [first_repo_state | other_repo_states] = repo_states
    try_and_rescue(fn -> Ecto.Adapters.SQL.query!(first_repo_state.repo, "XA COMMIT '#{first_repo_state.uuid}'", []) end,
                   fn -> rollback([first_repo_state]) end)

    # all repos try to XA COMMIT even if any XA COMMIT is failed
    try_and_rescue(fn -> other_repo_states |> Enum.each(fn %RepoState{repo: repo, uuid: uuid} -> Ecto.Adapters.SQL.query!(repo, "XA COMMIT '#{uuid}'", []) end) end,
                   fn -> commit(other_repo_states) end)

    result
  end

  defp adapter_key(pool) do
    {Ecto.Adapters.SQL, pool}
  end

  defp xa_key(%DBConnection{conn_ref: conn_ref}) do
    {__MODULE__, conn_ref}
  end

  def in_xa_transaction?(repo) do
    {pool, _} = repo.__pool__
    case Process.get(adapter_key(pool)) do
      nil -> false
      conn ->
        case Process.get(xa_key(conn)) do
          nil -> false
          true -> true
        end
    end
  end

  def transaction(repos, fun, opts \\ [])

  # just once repo
  def transaction([repo], fun, opts) do
    if in_xa_transaction?(repo) do
      raise "repo #{repo} is already in XA transaction."
    end

    # single transaction
    repo.transaction(fun, opts)
  end

  # two or more repos
  def transaction([_, _ | _] = repos, fun, opts) do
    # XA transaction

    for repo <- repos do
      if in_xa_transaction?(repo) do
        raise "repo #{repo} is already in XA transaction."
      end

      if repo.in_transaction?() do
        raise "repo #{repo} is already in transaction. XA transaction requires not in transaction."
      end
    end

    run_multi(repos, &with_xa(&1, repos, fun), opts, %{})
  end
end
