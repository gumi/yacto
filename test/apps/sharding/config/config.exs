use Mix.Config

config :sharding, Sharding.Repo.Default,
  adapter: Ecto.Adapters.MySQL,
  database: "sharding_default",
  username: "root",
  password: "",
  hostname: "localhost",
  port: "3306"

mods = for n <- 0..1 do
         mod = Module.concat(Sharding.Repo, "Player#{n}")
         config :sharding, mod,
           adapter: Ecto.Adapters.MySQL,
           database: "sharding_repo_player#{n}",
           username: "root",
           password: "",
           hostname: "localhost",
           port: "3306"
         mod
       end

config :sharding, ecto_repos: [Sharding.Repo.Default] ++ mods

config :yacto, :databases,
  %{default: %{module: Yacto.DB.Single,
               repo: Sharding.Repo.Default},
    player: %{module: Yacto.DB.Shard,
              repos: [Sharding.Repo.Player0, Sharding.Repo.Player1]}}
