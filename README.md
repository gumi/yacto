# Yacto

Ecto is a very handy library handling databases.
However, since there were some inconvenient parts to use on our own, I made a library called Yacto.

- [日本語版はこちら](TODO)

## About Yacto

Yacto is a library to support parts that were difficult to use with Ecto.
It has the following features.

- Automatic generation of a migration file
- Use of migration from another application
- Migration to a horizontally partitioned database
- Transaction across multiple databases (XA transaction)

### Automatic generation of a migration file

Yacto's migration is different from Ecto. Although Ecto defined the schema and migration separately, Yacto automatically outputs the migration file from the schema.

Specifically, assuming that the schema is defined as follows,

```elixir
defmodule MyApp.Player do
  use Yacto.Schema

  @impl Yacto.Schema
  def dbname() do
    :player
  end

  schema @auto_source do
    # sharding key
    field :player_id, :string, meta: [null: false, index: true]
    field :hp, :integer, default: 0, meta: [null: false]
    index :player_id, unique: true
  end
end
```

If you run `mix yacto.gen.migration` in this state, the following migration file will be output.

```elixir
defmodule MyApp.Migration20171122045225 do
  use Ecto.Migration

  def change(MyApp.Player) do
    create table("my_app_player")
    alter table("my_app_player") do
      add(:hp, :integer, [null: false])
      add(:player_id, :string, [null: false])
    end
    create index("my_app_player", [:player_id], [name: "player_id_index"])
    create index("my_app_player", [:player_id], [name: "player_id_index", unique: true])
  end

  def change(_other) do
    :ok
  end

  def __migration_structures__() do
    [
      {MyApp.Player, %Yacto.Migration.Structure{fields: [:id, :player_id, :hp], meta: %{attrs: %{hp: %{null: false}, player_id: %{null: false}}, indices: %{{[:player_id], []} => true, {[:player_id], [unique: true]} => true}}, source: "my_app_player", types: %{hp: :integer, id: :id, player_id: :string}}},
    ]
  end

  def __migration_version__() do
    20171122045225
  end
end
```

After that, if you run `mix yacto.migrate` command, this migration file will be applied in the database.
You are not necessary to write a migration file.

In addition, in this state, add the `:mp` field to the `MyApp.Player` schema and run `mix yacto.gen.migration`,
the following migration file is generated.

```elixir
defmodule MyApp.Player do
  ...

  schema @auto_source do
    ...

    # add a field
    field :mp, :integer, default: 0, meta: [null: false]

    ...
  end
end
```

```elixir
defmodule MyApp.Migration20171122052212 do
  use Ecto.Migration

  def change(MyApp.Player) do
    alter table("my_app_player") do
      add(:mp, :integer, [null: false])
    end
  end

  def change(_other) do
    :ok
  end

  def __migration_structures__() do
    [
      {MyApp.Player, %Yacto.Migration.Structure{fields: [:id, :player_id, :hp, :mp], meta: %{attrs: %{hp: %{null: false}, mp: %{null: false}, player_id: %{null: false}}, indices: %{{[:player_id], []} => true, {[:player_id], [unique: true]} => true}}, source: "my_app_player", types: %{hp: :integer, id: :id, mp: :integer, player_id: :string}}},
    ]
  end

  def __migration_version__() do
    20171122052212
  end
end
```

Only the previous differences are output to the migration file.
If you run `mix yacto.migrate`, this migration file will be applied in the database.


If none of the migration files have been applied to the database,
the above two migration files are applied sequentially.

### Use of migration from another application

Suppose there is an `other_app` application that uses the `my_app` application we created earlier.
Since `my_app` uses the database, you need to migrate for `my_app` on `other_app`.
With Yacto, after writing `config/config.exs`, you can migrate `my_app` just by executing the following command on `other_app`.

```
mix yacto.migrate --app my_app
```

With Ecto, it was necessary to write a migration file myself that other applications needed,
or to migrate in a different way specified by each application.
For applications using Yacto, you can migrate all in the same way.

### Migration to a horizontally partitioned database

TODO

### Transaction across multiple databases (XA transaction)

TODO

## Yacto Schema

TODO

### Automatic generation of table name

TODO

### Meta information

TODO

### Index

TODO

### Foreign key constraint

TODO


