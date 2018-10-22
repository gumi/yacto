use Mix.Config

config :custom_table_name, :ecto_repos, [CustomTableName.Repo0, CustomTableName.Repo1]

config :custom_table_name, CustomTableName.Repo0,
  database: "custom_table_name_repo0",
  username: "root",
  password: "",
  hostname: "localhost",
  port: "3306"

config :custom_table_name, CustomTableName.Repo1,
  database: "custom_table_name_repo1",
  username: "root",
  password: "",
  hostname: "localhost",
  port: "3306"

config :yacto, :databases, %{
  default: %{module: Yacto.DB.Single, repo: CustomTableName.Repo1},
  player: %{module: Yacto.DB.Shard, repos: [CustomTableName.Repo0, CustomTableName.Repo1]}
}

config :yacto, table_name_converter: {"^(.*)_schema(.*)_testdata", "\\1\\2"}
