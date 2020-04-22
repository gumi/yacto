defmodule Yacto.Migration.FileTest do
  use PowerAssert

  @migration_dir "_migrations"

  setup do
    ExUnit.Callbacks.on_exit(fn ->
      File.rm_rf!("_migrations")
    end)

    :ok
  end

  defp create_dummy(files) do
    File.rm_rf!("_migrations")

    for file <- files do
      path = Path.join(@migration_dir, file)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "")
    end
  end

  test "Yacto.Migration.File がちゃんと動作するか確認" do
    # この構成でファイルを作る
    files = [
      "Elixir.App.Mod1/0000-default-create-2019_11_26_170846.exs",
      "Elixir.App.Mod1/0001-default-change-2019_11_26_170847.exs",
      "Elixir.App.Mod1/0002-default-delete-2019_11_26_170848.exs",
      "Elixir.App.Mod2/0000-default-create-2019_11_26_170848.exs"
    ]

    create_dummy(files)

    {mods, []} = Yacto.Migration.File.list_migration_modules(@migration_dir)
    assert ["Elixir.App.Mod1", "Elixir.App.Mod2"] == mods

    {files, []} = Yacto.Migration.File.list_migration_files(@migration_dir, "Elixir.App.Mod1")

    file1 = %Yacto.Migration.File{
      version: 0,
      dbname: :default,
      operation: :create,
      datetime_str: "2019_11_26_170846",
      path: "Elixir.App.Mod1/0000-default-create-2019_11_26_170846.exs",
      schema_name: "Elixir.App.Mod1"
    }

    file2 = %Yacto.Migration.File{
      version: 1,
      dbname: :default,
      operation: :change,
      datetime_str: "2019_11_26_170847",
      path: "Elixir.App.Mod1/0001-default-change-2019_11_26_170847.exs",
      schema_name: "Elixir.App.Mod1"
    }

    file3 = %Yacto.Migration.File{
      version: 2,
      dbname: :default,
      operation: :delete,
      datetime_str: "2019_11_26_170848",
      path: "Elixir.App.Mod1/0002-default-delete-2019_11_26_170848.exs",
      schema_name: "Elixir.App.Mod1"
    }

    assert [file1, file2, file3] == files

    {files, []} = Yacto.Migration.File.list_migration_files(@migration_dir, "Elixir.App.Mod2")

    file4 = %Yacto.Migration.File{
      version: 0,
      dbname: :default,
      operation: :create,
      datetime_str: "2019_11_26_170848",
      path: "Elixir.App.Mod2/0000-default-create-2019_11_26_170848.exs",
      schema_name: "Elixir.App.Mod2"
    }

    assert [file4] == files
  end

  test "マイグレーションファイルのチェックが動作することを確認する" do
    # これは正しく動作する
    files = [
      "Elixir.App.Mod1/0000-default-create-2019_11_26_170846.exs",
      "Elixir.App.Mod1/0001-default-change-2019_11_26_170847.exs",
      "Elixir.App.Mod1/0002-default-delete-2019_11_26_170848.exs",
      "Elixir.App.Mod2/0000-default-create-2019_11_26_170848.exs"
    ]

    create_dummy(files)
    result = Yacto.Migration.File.check_migrations(@migration_dir)
    assert :ok == result

    # 同じバージョンのマイグレーションファイルが存在する
    files = [
      "Elixir.App.Mod1/0000-default-create-2019_11_26_170846.exs",
      "Elixir.App.Mod1/0001-default-change-2019_11_26_170847.exs",
      "Elixir.App.Mod1/0001-default-delete-2019_11_26_170848.exs",
      "Elixir.App.Mod2/0000-default-create-2019_11_26_170848.exs"
    ]

    create_dummy(files)
    result = Yacto.Migration.File.check_migrations(@migration_dir)

    expected =
      {:error,
       [
         "同じバージョンのファイルが存在しています: [\"Elixir.App.Mod1/0001-default-change-2019_11_26_170847.exs\", \"Elixir.App.Mod1/0001-default-delete-2019_11_26_170848.exs\"]"
       ]}

    assert expected == result

    # マイグレーションファイルがスキップしてる
    files = [
      "Elixir.App.Mod1/0000-default-create-2019_11_26_170846.exs",
      "Elixir.App.Mod1/0002-default-delete-2019_11_26_170848.exs",
      "Elixir.App.Mod2/0000-default-create-2019_11_26_170848.exs"
    ]

    create_dummy(files)
    result = Yacto.Migration.File.check_migrations(@migration_dir)

    expected =
      {:error,
       [
         "ファイルが0からの連番になっていません。期待していたバージョンは 0001 です: Elixir.App.Mod1/0002-default-delete-2019_11_26_170848.exs"
       ]}

    assert expected == result
  end
end
