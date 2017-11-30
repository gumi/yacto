# Yacto

[Ecto](https://hexdocs.pm/ecto/Ecto.html) is a very handy library handling databases.
However, since there were some inconvenient parts to use on our own, I made a library called Yacto.

[日本語ドキュメントはこちら](https://qiita.com/melpon/items/5c9b0645d5240cd22d0f)

# About Yacto

Yacto is a library to support parts that were difficult to use with Ecto.
It has the following features.

- Automatic generation of a migration file
- Use of migration from another application
- Migration to a horizontally partitioned database
- Transaction across multiple databases (XA transaction)

## Automatic generation of a migration file

Yacto's migration is different from Ecto. Although Ecto defined the schema and migration separately, *Yacto automatically outputs the migration file from the schema*.

Specifically, when the schema is defined as follows,

```elixir
defmodule MyApp.Player do
  use Yacto.Schema

  @impl Yacto.Schema
  def dbname() do
    :player
  end

  schema @auto_source do
    # sharding key
    field :player_id, :string, meta: [null: false, size: 64]
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
      add(:hp, :integer, [null: false, size: 64])
      add(:player_id, :string, [null: false])
    end
    create index("my_app_player", [:player_id], [name: "player_id_index", unique: true])
  end

  def change(_other) do
    :ok
  end

  def __migration_structures__() do
    [
      {MyApp.Player, %Yacto.Migration.Structure{fields: [:id, :player_id, :hp], meta: %{attrs: %{hp: %{null: false}, player_id: %{null: false, size: 64}}, indices: %{{[:player_id], [unique: true]} => true}}, source: "my_app_player", types: %{hp: :integer, id: :id, player_id: :string}}},
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
      {MyApp.Player, %Yacto.Migration.Structure{fields: [:id, :player_id, :hp, :mp], meta: %{attrs: %{hp: %{null: false}, mp: %{null: false}, player_id: %{null: false, size: 64}}, indices: %{{[:player_id], [unique: true]} => true}}, source: "my_app_player", types: %{hp: :integer, id: :id, mp: :integer, player_id: :string}}},
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

## Use of migration from another application

Suppose there is an `other_app` application that uses the `my_app` application we created earlier.
Since `my_app` uses the database, you need to migrate for `my_app` on `other_app`.
With Yacto, after writing `config/config.exs`, you can migrate `my_app` just by executing the following command on `other_app`.

```
mix yacto.migrate --app my_app
```

With Ecto, it was necessary to write a migration file myself that other applications needed,
or to migrate in a different way specified by each application.
For applications using Yacto, you can migrate all in the same way.

## Migration to a horizontally partitioned database

When partitioning the MyApp.Player schema horizontally, you should apply the migration file of this schema to multiple Repos.
For that, write it in the configuration file as follows.

```elixir
config :yacto, :databases,
  %{
    default: %{
      module: Yacto.DB.Single,
      repo: MyApp.Repo.Default,
    },
    player: %{
      module: Yacto.DB.Shard,
      repos: [MyApp.Repo.Player0, MyApp.Repo.Player1],
    },
  }
```

Recall that `MyApp.Player` had the following callback function.

```elixir
defmodule MyApp.Player do
  ...

  @impl Yacto.Schema
  def dbname() do
    :player
  end

  ...
end
```

This `:player` is the group name of Repo to which` MyApp.Player` belongs.
`MyApp.Player` belongs to the Repo group `:player`, and the `:player` Repo group is associated with Repos of `MyApp.Repo.Player0` and `MyApp.Repo.Player1` by the configuration file.

After writing the configuration file, just run `mix yacto.migrate`.
The migration file for `MyApp.Player` is applied to `MyApp.Repo.Player0` and `MyApp.Repo.Player1`.

When using a horizontally partitioned database, use `Yacto.DB.repo/2` to get a Repo.

```elixir
repo = Yacto.DB.repo(:player, player_id)
MyApp.Player |> repo.all()
```

### Use a horizontal partitioned application from other applications

Of course, you can also use this horizontally partitioned `my_app` application with `other_app`.
In `other_app` write the configuration file like below,

```elixir
config :yacto, :databases,
  %{
    default: %{
      module: Yacto.DB.Single,
      repo: OtherApp.Repo.Default,
    },
    player: %{
      module: Yacto.DB.Shard,
      repos: [OtherApp.Repo.Player0, OtherApp.Repo.Player1, OtherApp.Repo.Player2],
    },
  }
```

When you run `mix yacto.migrate --app my_app`, the migration file for `MyApp.Player` schema is applied to `OtherApp.Repo.Player0`, `OtherApp.Repo.Player1` and `OtherApp.Repo.Player2`.

## Transaction across multiple databases (XA transaction)

With `Yacto.transaction/2`, transactions can be started to multiple databases.

```elixir
# Since two or more Repos are specified, an XA transaction is started
Yacto.transaction([:default,
                   {:player, player_id1},
                   {:player, player_id2}], fn ->
  default_repo = Yacto.DB.repo(:default)
  player1_repo = Yacto.DB.repo(:player, player_id1)
  player2_repo = Yacto.DB.repo(:player, player_id2)

  # Operate databases here
  ...

# All XA transactions are committed here
end)
```

`Yacto.transaction/2` will make transactions for the following three Repos.

- Repo `MyApp.Repo.Default` of`: default`
- Repo sharded with `player_id1`
- Repo sharded with `player_id 2`

The last two may have the same Repo depending on the shard key, so Repo to use is either 2 or 3.
When you start transactions using more than one Repo, those transactions automatically become XA transactions.

XA transactions can not reliably prevent inconsistencies, but they can be prevented than starting separate transactions.
However, since this library does not provide a mechanism to solve the transactions left in `XA RECOVER`, it needs to be prepared separately.

# Details of Yacto Schema

There is a part not yet explained about Yacto's schema, so I will explain it in more detail.

As I wrote in the beginning, Yacto's schema is defined as follows.

```elixir
defmodule MyApp.Player do
  use Yacto.Schema

  @impl Yacto.Schema
  def dbname() do
    :player
  end

  schema @auto_source do
    field :player_id, :string, meta: [null: false, size: 64]
    field :hp, :integer, default: 0, meta: [null: false]
    index :player_id, unique: true
  end
end
```

Basically it is the same as `Ecto.Schema`.
The schema generated by `Yacto.Schema` is compatible with the schema generated by` Ecto.Schema`.
However, since the migration setting is necessary, the amount of description increases more than `Ecto.Schema`.

## Automatic generation of table name

`@auto_source` defines the table name automatically generated from the module name.
In most cases, using `@auto_source` will always be fine.

## Meta information

```elixir
    field :player_id, :string, meta: [null: false, size: 64]
    field :hp, :integer, default: 0, meta: [null: false]
```

This is almost the same as the `field/3` function of `Ecto.Schema`, except that it has a `:meta` option.
The `:meta` option is a place to store information on migration, specifying whether the field is nullable, the size of the string, and so on.

The options that can be specified are as follows.

- `:null`: Whether the field is nullable (`true` by default)
- `:size`: The size of the string (It is used like `VARCHAR (<size>)`) (`255` by default)
- `:default`: Default value for that field (the initial value of each type by default)
- `:index`: Whether to index in this field (`false` by default)
- `:type`: Specify the type at migration (type specified by `field/3` by default)

## Index

```elixir
    index :player_id, unique: true
```

You can generate an index with `index/2`.
Although you can specify an index in the `:meta` option of `field/3`, you can also generate composite indexes and unique indexes using `index/2`.

To make it a composite index, specify it as a list like `index [:player_id, :hp]`.
To change the index to a unique index, specify `unique: true` as an option.

## Foreign key constraint

Not supported.

I think it is generally necessary, but I do not need it yet.
