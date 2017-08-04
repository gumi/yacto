use Mix.Config

# config for testing
config :yacto, ecto_repos: [Yacto.XATest.Repo0,
                            Yacto.XATest.Repo1]

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
