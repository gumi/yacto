import Config

# config for testing

config :yacto,
  ecto_repos: [
    Yacto.XATest.Repo0,
    Yacto.XATest.Repo1,
    Yacto.QueryTest.Repo.Default,
    Yacto.QueryTest.Repo.Player0,
    Yacto.QueryTest.Repo.Player1
  ]

config :yacto, Yacto.XATest.Repo0,
  database: "yacto_xa_repo0",
  username: "root",
  password: "",
  hostname: "localhost",
  port: 3306

config :yacto, Yacto.XATest.Repo1,
  database: "yacto_xa_repo1",
  username: "root",
  password: "",
  hostname: "localhost",
  port: 3306

config :yacto, Yacto.QueryTest.Repo.Default,
  database: "yacto_query_repo_default",
  username: "root",
  password: "",
  hostname: "localhost",
  port: 3306

config :yacto, Yacto.QueryTest.Repo.Player0,
  database: "yacto_query_repo_player0",
  username: "root",
  password: "",
  hostname: "localhost",
  port: 3306

config :yacto, Yacto.QueryTest.Repo.Player1,
  database: "yacto_query_repo_player1",
  username: "root",
  password: "",
  hostname: "localhost",
  port: 3306

config :yacto, :databases, %{
  default: %{module: Yacto.DB.Single, repo: Yacto.QueryTest.Repo.Default},
  player: %{
    module: Yacto.DB.Shard,
    repos: [Yacto.QueryTest.Repo.Player0, Yacto.QueryTest.Repo.Player1]
  }
}
