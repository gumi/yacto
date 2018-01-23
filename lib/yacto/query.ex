defmodule Yacto.Query do
  # under constructing
  @moduledoc false

  require Ecto.Query

  defp pop!(kwargs, key) do
    value = Keyword.fetch!(kwargs, key)
    kwargs = Keyword.delete(kwargs, key)
    {value, kwargs}
  end

  defp ensure_empty([]), do: :ok

  defp ensure_empty(kwargs) do
    raise "unnecessary keywords: #{inspect(kwargs)}"
  end

  def get(schema, repo, kwargs) do
    {lock, kwargs} = pop!(kwargs, :lock)
    {lookup, kwargs} = pop!(kwargs, :lookup)
    {opts, kwargs} = Keyword.pop(kwargs, :opts, [])
    ensure_empty(kwargs)

    query =
      schema
      |> Ecto.Query.where(^lookup)

    query =
      if lock do
        query |> Ecto.Query.lock("FOR UPDATE")
      else
        query
      end

    query |> repo.one!(opts)
  end

  def create(schema, repo, kwargs) do
    {fields, kwargs} = pop!(kwargs, :fields)
    {opts, kwargs} = Keyword.pop(kwargs, :opts, [])
    ensure_empty(kwargs)

    schema
    |> struct(fields)
    |> repo.insert!(opts)
  end

  def get_or_new(schema, repo, kwargs) do
    {lock, kwargs} = pop!(kwargs, :lock)
    {lookup, kwargs} = pop!(kwargs, :lookup)
    {defaults, kwargs} = Keyword.pop(kwargs, :defaults, [])
    {opts, kwargs} = Keyword.pop(kwargs, :opts, [])
    ensure_empty(kwargs)

    if lock do
      query =
        schema
        |> Ecto.Query.where(^lookup)

      case repo.one(query, opts) do
        nil ->
          # insert
          record = struct(schema, Keyword.merge(lookup, defaults))

          try do
            repo.insert!(record)
          else
            record -> {record, true}
          rescue
            _ in Ecto.ConstraintError ->
              # duplicate key
              query =
                schema
                |> Ecto.Query.where(^lookup)
                |> Ecto.Query.lock("FOR UPDATE")

              record = repo.one!(query)
              {record, false}
          end

        _ ->
          # retry SELECT with FOR UPDATE
          query =
            schema
            |> Ecto.Query.where(^lookup)
            |> Ecto.Query.lock("FOR UPDATE")

          record = repo.one!(query)
          {record, false}
      end
    else
      query =
        schema
        |> Ecto.Query.where(^lookup)

      case repo.one(query, opts) do
        nil ->
          {struct(schema, Keyword.merge(lookup, defaults)), true}

        record ->
          {record, false}
      end
    end
  end

  def save(repo, kwargs) do
    {record, kwargs} = pop!(kwargs, :record)
    {opts, kwargs} = Keyword.pop(kwargs, :opts, [])
    ensure_empty(kwargs)

    schema = record.__struct__
    set = record |> Map.drop([:__meta__]) |> Map.from_struct() |> Map.to_list()

    {1, _} =
      schema
      |> Ecto.Query.where(id: ^record.id)
      |> Ecto.Query.update(set: ^set)
      |> repo.update_all([], opts)

    record
  end
end
