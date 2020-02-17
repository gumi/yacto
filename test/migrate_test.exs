defmodule Yacto.MigrateTest do
  use PowerAssert

  @databases %{
    default: %{module: Yacto.DB.Single, repo: Yacto.MigratorTest.Repo1},
    player: %{module: Yacto.DB.Shard, repos: [Yacto.MigratorTest.Repo0, Yacto.MigratorTest.Repo1]}
  }

  setup do
    repo0_config = [
      database: "migrator_repo0",
      username: "root",
      password: "",
      hostname: "localhost",
      port: 3306
    ]

    repo1_config = [
      database: "migrator_repo1",
      username: "root",
      password: "",
      hostname: "localhost",
      port: 3306
    ]

    for {repo, config} <- [
          {Yacto.MigratorTest.Repo0, repo0_config},
          {Yacto.MigratorTest.Repo1, repo1_config}
        ] do
      _ = repo.__adapter__.storage_down(config)
      :ok = repo.__adapter__.storage_up(config)
    end

    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.MigratorTest.Repo0, repo0_config})
    {:ok, _} = ExUnit.Callbacks.start_supervised({Yacto.MigratorTest.Repo1, repo1_config})

    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir(:yacto))
    _ = File.rm_rf(Yacto.Migration.Util.get_migration_dir_for_gen())

    Application.put_env(:yacto, :databases, @databases)
    ExUnit.Callbacks.on_exit(fn -> Application.delete_env(:yacto, :databases) end)

    :ok
  end

  test "migrate" do
    migration_dir = Yacto.Migration.Util.get_migration_dir_for_gen()
    Mix.Task.rerun("yacto.gen.migration2", ["--prefix", "Yacto.MigratorTest"])
    Mix.Task.rerun("yacto.migrate", ["--migration-dir", migration_dir])
  end
end
