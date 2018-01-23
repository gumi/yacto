use Mix.Config

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
  adapter: Ecto.Adapters.MySQL,
  database: "yact_xa_repo0",
  username: "root",
  password: "",
  hostname: "localhost",
  port: "3306"

config :yacto, Yacto.XATest.Repo1,
  adapter: Ecto.Adapters.MySQL,
  database: "yact_xa_repo1",
  username: "root",
  password: "",
  hostname: "localhost",
  port: "3306"

config :yacto, Yacto.QueryTest.Repo.Default,
  adapter: Ecto.Adapters.MySQL,
  database: "yact_query_repo_default",
  username: "root",
  password: "",
  hostname: "localhost",
  port: "3306"

config :yacto, Yacto.QueryTest.Repo.Player0,
  adapter: Ecto.Adapters.MySQL,
  database: "yact_query_repo_player0",
  username: "root",
  password: "",
  hostname: "localhost",
  port: "3306"

config :yacto, Yacto.QueryTest.Repo.Player1,
  adapter: Ecto.Adapters.MySQL,
  database: "yact_query_repo_player1",
  username: "root",
  password: "",
  hostname: "localhost",
  port: "3306"

config :yacto, :databases, %{
  default: %{module: Yacto.DB.Single, repo: Yacto.QueryTest.Repo.Default},
  player: %{
    module: Yacto.DB.Shard,
    repos: [Yacto.QueryTest.Repo.Player0, Yacto.QueryTest.Repo.Player1]
  }
}
