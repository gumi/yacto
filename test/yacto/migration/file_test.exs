defmodule Yacto.Migration.FileTest do
  use PowerAssert

  @migration_dir "_migrations"

  test "Yacto.Migration.File がちゃんと動作するか確認" do
    # この構成でファイルを作る
    files = [
      "Elixir.App.Mod1/0001-default-create-2019_11_26_170846.exs",
      "Elixir.App.Mod1/0002-default-change-2019_11_26_170847.exs",
      "Elixir.App.Mod1/0003-default-delete-2019_11_26_170848.exs",
      "Elixir.App.Mod2/0001-default-create-2019_11_26_170848.exs"
    ]

    for file <- files do
      path = Path.join(@migration_dir, file)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "")
    end

    ExUnit.Callbacks.on_exit(fn ->
      File.rm_rf!("_migrations")
    end)

    {mods, []} = Yacto.Migration.File.list_migration_modules(@migration_dir)
    assert ["Elixir.App.Mod1", "Elixir.App.Mod2"] == mods

    {files, []} = Yacto.Migration.File.list_migration_files(@migration_dir, "Elixir.App.Mod1")

    file1 = %Yacto.Migration.File{
      version: 1,
      dbname: :default,
      operation: :create,
      datetime_str: "2019_11_26_170846",
      path: "Elixir.App.Mod1/0001-default-create-2019_11_26_170846.exs"
    }

    file2 = %Yacto.Migration.File{
      version: 2,
      dbname: :default,
      operation: :change,
      datetime_str: "2019_11_26_170847",
      path: "Elixir.App.Mod1/0002-default-change-2019_11_26_170847.exs"
    }

    file3 = %Yacto.Migration.File{
      version: 3,
      dbname: :default,
      operation: :delete,
      datetime_str: "2019_11_26_170848",
      path: "Elixir.App.Mod1/0003-default-delete-2019_11_26_170848.exs"
    }

    assert [file1, file2, file3] == files

    {files, []} = Yacto.Migration.File.list_migration_files(@migration_dir, "Elixir.App.Mod2")

    file4 = %Yacto.Migration.File{
      version: 1,
      dbname: :default,
      operation: :create,
      datetime_str: "2019_11_26_170848",
      path: "Elixir.App.Mod2/0001-default-create-2019_11_26_170848.exs"
    }

    assert [file4] == files
  end
end
