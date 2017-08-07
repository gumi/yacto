use Mix.Config

config :migration_router, :ecto_repos, [MigrationRouter.Repo.Default,
                                        MigrationRouter.Repo.Player1,
                                        MigrationRouter.Repo.Player2]

config :migration_router, MigrationRouter.Repo.Default,
       adapter: Ecto.Adapters.MySQL,
       database: "migration_router_default",
       username: "root",
       password: "",
       hostname: "localhost",
       port: "3306"

config :migration_router, MigrationRouter.Repo.Player1,
       adapter: Ecto.Adapters.MySQL,
       database: "migration_router_player1",
       username: "root",
       password: "",
       hostname: "localhost",
       port: "3306"

config :migration_router, MigrationRouter.Repo.Player2,
       adapter: Ecto.Adapters.MySQL,
       database: "migration_router_player2",
       username: "root",
       password: "",
       hostname: "localhost",
       port: "3306"

config :yacto, :databases,
  %{default: %{module: Yacto.DB.Single,
               repo: MigrationRouter.Repo.Default},
    player: %{module: Yacto.DB.Shard,
              repos: [MigrationRouter.Repo.Player1,
                      MigrationRouter.Repo.Player2]}}
