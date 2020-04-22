defmodule Yacto.Migration.SchemaMigration do
  use Ecto.Schema
  require Ecto.Query

  @table_name "yacto_schema_migrations"
  @primary_key false
  schema @table_name do
    field(:app, :string)
    field(:schema, :string)
    field(:version, :integer)
    timestamps(updated_at: false)
  end

  @opts [timeout: :infinity, log: false]

  def ensure_schema_migrations_table!(repo) do
    adapter = repo.__adapter__
    create_migrations_table(adapter, repo)
  end

  def migrated_versions(repo, app, schema) when is_atom(app) and is_atom(schema) do
    app = Atom.to_string(app)
    schema = Atom.to_string(schema)

    __MODULE__
    |> Ecto.Query.where(app: ^app, schema: ^schema)
    |> Ecto.Query.select([:version])
    |> Ecto.Query.order_by([:version])
    |> repo.all(@opts)
    |> Enum.map(fn u -> u.version end)
  end

  def up(repo, app, schema, version) when is_atom(app) and is_atom(schema) do
    app = Atom.to_string(app)
    schema = Atom.to_string(schema)
    record = %__MODULE__{app: app, schema: schema, version: version}
    record |> repo.insert!(@opts)
  end

  def down(repo, app, schema, version) when is_atom(app) and is_atom(schema) do
    app = Atom.to_string(app)
    schema = Atom.to_string(schema)

    __MODULE__
    |> Ecto.Query.where(app: ^app, schema: ^schema, version: ^version)
    |> repo.delete_all(@opts)
  end

  def drop(repo) do
    adapter = repo.__adapter__
    delete_migrations_table(adapter, repo)
  end

  def drop_and_create(repo) do
    adapter = repo.__adapter__
    delete_migrations_table(adapter, repo)
    create_migrations_table(adapter, repo)
  end

  defp delete_migrations_table(adapter, repo) do
    table = %Ecto.Migration.Table{name: @table_name}
    adapter.execute_ddl(repo, {:drop_if_exists, table}, @opts)
  end

  defp create_migrations_table(adapter, repo) do
    table = %Ecto.Migration.Table{name: @table_name}

    # DDL queries do not log, so we do not need to pass log: false here.
    adapter.execute_ddl(
      repo,
      {:create_if_not_exists, table,
       [
         {:add, :app, :string, null: false},
         {:add, :schema, :string, null: false},
         {:add, :version, :bigint, null: false},
         {:add, :inserted_at, :naive_datetime, null: false}
       ]},
      @opts
    )
  end
end
