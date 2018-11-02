defmodule Yacto.Repo.Helper.Helper do
  # this module is copied from Ecto.Repo.Queryable
  @moduledoc false

  require Ecto.Query

  # defp field(ix, field) when is_integer(ix) and is_atom(field) do
  #  {{:., [], [{:&, [], [ix]}, field]}, [], []}
  # end

  defp assert_schema!(%{from: %{source: {_source, schema}}}) when schema != nil, do: schema

  defp assert_schema!(query) do
    raise Ecto.QueryError,
      query: query,
      message: "expected a from expression with a schema"
  end

  def query_for_get(repo, _queryable, nil) do
    raise ArgumentError, "cannot perform #{inspect(repo)}.get/2 because the given value is nil"
  end

  def query_for_get(repo, queryable, id) do
    query = Ecto.Queryable.to_query(queryable)
    schema = assert_schema!(query)

    case schema.__schema__(:primary_key) do
      [pk] ->
        Ecto.Query.from(x in query, where: field(x, ^pk) == ^id)

      pks ->
        raise ArgumentError,
              "#{inspect(repo)}.get/2 requires the schema #{inspect(schema)} " <>
                "to have exactly one primary key, got: #{inspect(pks)}"
    end
  end

  def query_for_get_by(_repo, queryable, clauses) do
    Ecto.Query.where(queryable, [], ^Enum.to_list(clauses))
  end
end

defmodule Yacto.Repo.Helper do
  @moduledoc """
  Helper functions for your repo.

  ```
  defmodule MyApp.Repo do
    use Ecto.Repo, otp_app: :my_app
    use Yacto.Repo.Helper
  end

  person = MyApp.Repo.get_or_insert_for_update(Person, [name: "foo"], %Person{name: "foo", value: 10})
  # person is exclusive locked.

  changeset = Person.changeset(person, [value: person.value + 5])
  _person = MyApp.Repo.update!(changeset)
  ```
  """

  alias Yacto.Repo.Helper.Helper

  defmacro __using__(_) do
    quote do
      def get_for_update(queryable, id, opts \\ []) do
        query = Helper.query_for_get(__MODULE__, queryable, id)
        query |> Yacto.Query.for_update() |> __MODULE__.one(opts)
      end

      def get_for_update!(queryable, id, opts \\ []) do
        query = Helper.query_for_get(__MODULE__, queryable, id)
        query |> Yacto.Query.for_update() |> __MODULE__.one!(opts)
      end

      def get_by_for_update(queryable, clauses, opts \\ []) do
        query = Helper.query_for_get_by(__MODULE__, queryable, clauses)
        query |> Yacto.Query.for_update() |> __MODULE__.one(opts)
      end

      def get_by_for_update!(queryable, clauses, opts \\ []) do
        query = Helper.query_for_get_by(__MODULE__, queryable, clauses)
        query |> Yacto.Query.for_update() |> __MODULE__.one!(opts)
      end

      def find(queryable, clauses, opts \\ []) do
        query = Helper.query_for_get_by(__MODULE__, queryable, clauses)
        query |> __MODULE__.all(opts)
      end

      def find_for_update(queryable, clauses, opts \\ []) do
        query = Helper.query_for_get_by(__MODULE__, queryable, clauses)
        query |> Yacto.Query.for_update() |> __MODULE__.all(opts)
      end

      def delete_by(queryable, clauses, opts \\ []) do
        query = Helper.query_for_get_by(__MODULE__, queryable, clauses)
        query |> __MODULE__.delete_all(opts)
      end

      def delete_by!(queryable, clauses, opts \\ []) do
        case delete_by(queryable, clauses, opts) do
          {0, _} ->
            raise Ecto.NoResultsError, queryable: queryable

          otherwise ->
            otherwise
        end
      end

      def count(queryable, clauses, opts \\ []) do
        require Ecto.Query

        query = Helper.query_for_get_by(__MODULE__, queryable, clauses)
        query |> Ecto.Query.select(count("*")) |> __MODULE__.one!(opts)
      end

      def get_by_or_new(queryable, clauses, default_struct, opts \\ []) do
        case __MODULE__.get_by(queryable, clauses, opts) do
          nil ->
            {default_struct, true}

          record ->
            {record, false}
        end
      end

      def get_by_or_insert_for_update(queryable, clauses, default_struct_or_changeset, opts \\ []) do
        case __MODULE__.get_by(queryable, clauses, opts) do
          nil ->
            # insert
            try do
              __MODULE__.insert!(default_struct_or_changeset)
            else
              record -> {record, true}
            rescue
              _ in Ecto.ConstraintError ->
                # duplicate key
                record = get_by_for_update!(queryable, clauses, opts)
                {record, false}
            end

          _ ->
            # retry SELECT with FOR UPDATE
            record = get_by_for_update!(queryable, clauses, opts)
            {record, false}
        end
      end
    end
  end
end
