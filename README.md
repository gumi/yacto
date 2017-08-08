# Yacto

Yet another Ecto library.

The library provides below features:

- Schema first migration
- Sharding databases
- Transactions across multiple databases (XA transaction)

Here is an example:

```elixir
# In your config/config.exs file
config :my_app, ecto_repos: [MyApp.Repo.Default,
                             MyApp.Repo.Player0,
                             MyApp.Repo.Player1]

config :my_app, MyApp.Repo.Default,
  adapter: Ecto.Adapters.MySQL,
  database: "myapp_repo_default",
  username: "root",
  password: "",
  hostname: "localhost"

config :my_app, MyApp.Repo.Player0,
  adapter: Ecto.Adapters.MySQL,
  database: "myapp_repo_player0",
  username: "root",
  password: "",
  hostname: "localhost"

config :my_app, MyApp.Repo.Player1,
  adapter: Ecto.Adapters.MySQL,
  database: "myapp_repo_player1",
  username: "root",
  password: "",
  hostname: "localhost"

config :yacto, :databases,
  %{default: %{module: Yacto.DB.Single,
               repo: MyApp.Repo.Default},
    # player databases are sharded by player id
    player: %{module: Yacto.DB.Shard,
              repos: [MyApp.Repo.Player0,
                      MyApp.Repo.Player1]}}

# In your application code
defmodule MyApp.Repo.Default do
  use Ecto.Repo, otp_app: :my_app
end
defmodule MyApp.Repo.Player0 do
  use Ecto.Repo, otp_app: :my_app
end
defmodule MyApp.Repo.Player1 do
  use Ecto.Repo, otp_app: :my_app
end

defmodule MyApp.VersionInfo do
  use Yacto.Schema

  def dbname(), do: :default

  schema @auto_source do
    field :app_name, :string, meta: [size: 128, null: false, index: true]
    field :version, :integer, meta: [null: false]
    field :value, :integer, meta: [null: false]
    index [:app_name, :version], unique: true
  end
end

defmodule MyApp.Player do
  use Yacto.Schema

  def dbname(), do: :player

  schema @auto_source do
    # sharding key
    field :player_id, :string, meta: [null: false, index: true]
    field :hp, :integer, default: 0, meta: [null: false]
    index :player_id, unique: true
  end
end

defmodule MyApp.Application do
  def heal(player_id) do
    # get a player from sharded databases with lock
    player = MyApp.Player.Query.get(player_id, lock: true, lookup: [player_id: player_id])

    # update and save to the database
    player = %{player | hp: player.hp + 10}
    MyApp.Player.Query.save(player_id, record: player)
  end

  def run() do
    player_id = "xxxx-yyyy-zzzz"
    # start XA transaction
    Yacto.transaction([:default,
                       {:player, player_id}], fn ->
      {version_info, created} = MyApp.VersionInfo.Query.get_or_new(nil, lock: true, lookup: [app_name: "my_app", version: 1234], defaults: [value: 0])
      if created do
        heal(player_id)
      end
      version_info = %{version_info | value: version_info.value + 1}
      MyApp.VersionInfo.Query.save(nil, record: version_info)
    end)
  end
end
```

## Migration

Generate migration file:

```
mix yacto.gen.migration
```

The command generates a migration file `priv/migrations/20170808100652_my_app.exs`.

```elixir
defmodule MyApp.Migration20170808100652 do
  use Ecto.Migration

  def change(MyApp.Player) do
    create table(String.to_atom("my_app_player"))
    alter table(String.to_atom("my_app_player")), do: add(:hp, :integer, [])
    alter table(String.to_atom("my_app_player")), do: add(:player_id, :string, [])
    alter table(String.to_atom("my_app_player")), do: modify(:hp, :integer, [null: false])
    alter table(String.to_atom("my_app_player")), do: modify(:player_id, :string, [null: false])
    create index(String.to_atom("my_app_player"), [:player_id], [])
    create index(String.to_atom("my_app_player"), [:player_id], [unique: true])
  end
  def change(MyApp.VersionInfo) do
    create table(String.to_atom("my_app_version_info"))
    alter table(String.to_atom("my_app_version_info")), do: add(:app_name, :string, [])
    alter table(String.to_atom("my_app_version_info")), do: add(:value, :integer, [])
    alter table(String.to_atom("my_app_version_info")), do: add(:version, :integer, [])
    alter table(String.to_atom("my_app_version_info")), do: modify(:app_name, :string, [null: false, size: 128])
    alter table(String.to_atom("my_app_version_info")), do: modify(:value, :integer, [null: false])
    alter table(String.to_atom("my_app_version_info")), do: modify(:version, :integer, [null: false])
    create index(String.to_atom("my_app_version_info"), [:app_name], [])
    create index(String.to_atom("my_app_version_info"), [:app_name, :version], [unique: true])
  end

  def change(_other) do
    :ok
  end

  def __migration_structures__() do
    [
      %Yacto.Migration.Structure{fields: [:id, :player_id, :hp], meta: %{attrs: %{hp: %{null: false}, player_id: %{null: false}}, indices: %{{[:player_id], []} => true, {[:player_id], [unique: true]} => true}}, source: "my_app_player", types: %{hp: :integer, id: :id, player_id: :string}},
      %Yacto.Migration.Structure{fields: [:id, :app_name, :version, :value], meta: %{attrs: %{app_name: %{null: false, size: 128}, value: %{null: false}, version: %{null: false}}, indices: %{{[:app_name], []} => true, {[:app_name, :version], [unique: true]} => true}}, source: "my_app_version_info", types: %{app_name: :string, id: :id, value: :integer, version: :integer}},
    ]
  end

  def __migration_version__() do
    20170808100652
  end
end
```

If the migration file is not what you want, change `change(MyApp.Player)` or `change(MyApp.VersionInfo)`.

In order to migrate, execute the following command:

```
mix yacto.migrate
```

## Sharding

In order to shard databases, set `Yacto.DB.Shard` in configuration.

```
config :yacto, :databases,
  %{player: %{module: Yacto.DB.Shard,
              repos: [MyApp.Repo.Player0,
                      MyApp.Repo.Player1]}}
```

Then, a sharding schema implements `dbname/0` function that return `:player`.

```
defmodule MyApp.Player do
  use Yacto.Schema

  def dbname(), do: :player

  schema @auto_source do
    ...
  end
end
```

Following query is sharded by `player_id`.

```
# player_id is the sharding key
MyApp.Player.Query.get(player_id, lock: true, lookup: [player_id: player_id])
```
