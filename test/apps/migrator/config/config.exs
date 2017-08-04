use Mix.Config

config :migrator, :ecto_repos, [Migrator.Repo0,
                                Migrator.Repo1]

config :migrator, Migrator.Repo0,
       adapter: Ecto.Adapters.MySQL,
       database: "ecto_migration_repo0",
       username: "root",
       password: "",
       hostname: "localhost",
       port: "3306"

config :migrator, Migrator.Repo1,
       adapter: Ecto.Adapters.MySQL,
       database: "ecto_migration_repo1",
       username: "root",
       password: "",
       hostname: "localhost",
       port: "3306"

config :migrator, :migration_routers, [Migrator.Router1,
                                       Migrator.Router2]
