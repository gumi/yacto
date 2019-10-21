import Config

# config for testing

config :yacto, :databases, %{
  default: %{module: Yacto.DB.Single, repo: Yacto.QueryTest.Repo.Default},
  player: %{
    module: Yacto.DB.Shard,
    repos: [Yacto.QueryTest.Repo.Player0, Yacto.QueryTest.Repo.Player1]
  }
}
