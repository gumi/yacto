use Mix.Config

config :migration_router, :ecto_repos, [MigrationRouter.Repo0,
                                        MigrationRouter.Repo1]

config :migration_router, MigrationRouter.Repo0,
       adapter: Ecto.Adapters.MySQL,
       database: "ecto_migration_repo0",
       username: "root",
       password: "",
       hostname: "localhost",
       port: "3306"

config :migration_router, MigrationRouter.Repo1,
       adapter: Ecto.Adapters.MySQL,
       database: "ecto_migration_repo1",
       username: "root",
       password: "",
       hostname: "localhost",
       port: "3306"

config :migration_router, :migration_routers, [MigrationRouter.Router1,
                                               MigrationRouter.Router2]
