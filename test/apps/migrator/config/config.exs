use Mix.Config

config :migrator, :ecto_repos, [Migrator.Repo0, Migrator.Repo1]

config :migrator, Migrator.Repo0,
  database: "migrator_repo0",
  username: "root",
  password: "",
  hostname: "localhost",
  port: 3306

config :migrator, Migrator.Repo1,
  database: "migrator_repo1",
  username: "root",
  password: "",
  hostname: "localhost",
  port: 3306

config :yacto, :databases, %{
  default: %{module: Yacto.DB.Single, repo: Migrator.Repo1},
  player: %{module: Yacto.DB.Shard, repos: [Migrator.Repo0, Migrator.Repo1]}
}
