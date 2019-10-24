defmodule Yacto.Migration.UtilTest do
  use PowerAssert

  defp test_apply_myers_difference(list1, list2) do
    assert list2 ==
             Yacto.Migration.Util.apply_myers_difference(
               list1,
               List.myers_difference(list1, list2)
             )
  end

  test "apply_myers_difference" do
    test_apply_myers_difference([], [])
    test_apply_myers_difference([], [:a, :b])
    test_apply_myers_difference([:a, :b], [])
    test_apply_myers_difference([:a, :b], [:a])
    test_apply_myers_difference([:a], [:a, :b])
    test_apply_myers_difference([:a, :b], [:a, :b])
    test_apply_myers_difference([:a, :b], [:c, :d])
    test_apply_myers_difference([:a, :b, :c], [:a, :d, :c])
  end

  test "migration" do
    assert Path.join([File.cwd!(), "_build", "test", "lib", "yacto", "priv", "migrations"]) ==
             Yacto.Migration.Util.get_migration_dir(:yacto)

    assert "foo/bar" == Yacto.Migration.Util.get_migration_dir(:yacto, "foo/bar")
    dir = Yacto.Migration.Util.get_migration_dir(:yacto)
    _ = File.rm_rf(dir)
    assert [] == Yacto.Migration.Util.get_migration_files(:yacto)
    path1 = Path.join(dir, "1234-12-34T123456_yacto.exs")
    path2 = Path.join(dir, "5678-56-78T567890_yacto.exs")
    _ = File.mkdir_p!(dir)
    _ = File.write(path1, "test1")
    _ = File.write(path2, "test2")
    assert [path1, path2] == Yacto.Migration.Util.get_migration_files(:yacto)
    assert path1 == Yacto.Migration.Util.get_migration_path(:yacto, 12_341_234_123_456)
    assert path2 == Yacto.Migration.Util.get_migration_path(:yacto, 56_785_678_567_890)
    _ = File.rm_rf(dir)
  end

  test "get_all_schema" do
    require Yacto.Migration.SchemaMigration
    assert Yacto.Migration.SchemaMigration in Yacto.Migration.Util.get_all_schema(:yacto)

    assert [Yacto.Migration.SchemaMigration] ==
             Yacto.Migration.Util.get_all_schema(:yacto, Yacto.Migration)

    assert [Yacto.Migration.SchemaMigration] ==
             Yacto.Migration.Util.get_all_schema(:yacto, Yacto.Migration.SchemaMigration)

    assert [] == Yacto.Migration.Util.get_all_schema(:yacto, FooBar)
  end

  defp make_migrations(xs) do
    for {file, module, version, preview_version} <- xs do
      %{
        file: file,
        module: module,
        version: version,
        preview_version: preview_version
      }
    end
  end


  describe "need_gen_migration?/1" do
    test "when an option 'migration: true' is passed to Yacto.Schema" do
      {:module, schema, _, _} = defmodule TestSchema do
        use Yacto.Schema, migration: true
      end
  
      assert Yacto.Migration.Util.need_gen_migration?(schema)
    end

    test "when an option 'migration: false' is passed to Yacto.Schema" do
      {:module, schema, _, _} = defmodule TestSchema do
        use Yacto.Schema, migration: false
      end

      refute Yacto.Migration.Util.need_gen_migration?(schema)
    end

    test "when an option 'migration' is NOT passed to Yacto.Schema" do
      {:module, schema, _, _} = defmodule TestSchema do
        use Yacto.Schema, migration: false
      end
      
      refute Yacto.Migration.Util.need_gen_migration?(schema)
    end
  end


  test "sort_migrations の正常系" do
    assert {:ok, []} == Yacto.Migration.Util.sort_migrations([])

    expected =
      make_migrations([
        {"aaa.exs", Mod, 1, :unspecified}
      ])

    input = Enum.shuffle(expected)
    assert {:ok, expected} == Yacto.Migration.Util.sort_migrations(input)

    expected =
      make_migrations([
        {"aaa.exs", Mod, 1, nil}
      ])

    input = Enum.shuffle(expected)
    assert {:ok, expected} == Yacto.Migration.Util.sort_migrations(input)

    expected =
      make_migrations([
        {"aaa.exs", Mod, 1, :unspecified},
        {"ccc.exs", Mod, 3, 1}
      ])

    input = Enum.shuffle(expected)
    assert {:ok, expected} == Yacto.Migration.Util.sort_migrations(input)

    expected =
      make_migrations([
        {"aaa.exs", Mod, 1, nil},
        {"bbb.exs", Mod, 2, 1},
        {"ccc.exs", Mod, 3, 2}
      ])

    input = Enum.shuffle(expected)
    assert {:ok, expected} == Yacto.Migration.Util.sort_migrations(input)

    expected =
      make_migrations([
        {"aaa.exs", Mod, 1, :unspecified},
        {"bbb.exs", Mod, 2, :unspecified},
        {"ccc.exs", Mod, 3, 2}
      ])

    input = Enum.shuffle(expected)
    assert {:ok, expected} == Yacto.Migration.Util.sort_migrations(input)
  end

  test "sort_migrations の異常系" do
    input =
      make_migrations([
        {"aaa.exs", Mod, 1, :unspecified},
        {"bbb.exs", Mod, 1, :unspecified}
      ])

    message = "同じバージョン 1 があります。aaa.exs と bbb.exs"
    assert {:error, [message]} == Yacto.Migration.Util.sort_migrations(input)

    input =
      make_migrations([
        {"bbb.exs", Mod, 2, 1}
      ])

    message = "bbb.exs が指定している直前のバージョン 1 が存在しません"
    assert {:error, [message]} == Yacto.Migration.Util.sort_migrations(input)

    input =
      make_migrations([
        {"aaa.exs", Mod, 1, :unspecified},
        {"bbb.exs", Mod, 2, 1},
        {"ccc.exs", Mod, 3, 1}
      ])

    message =
      "ルートが一意に決定できません。\n" <>
        "新旧のマイグレーションファイルが混ざっている可能性があります。\n" <> "ルート候補:\n" <> "- bbb.exs\n" <> "- ccc.exs"

    assert {:error, [message]} == Yacto.Migration.Util.sort_migrations(input)

    input =
      make_migrations([
        {"aaa.exs", Mod, 1, nil},
        {"bbb.exs", Mod, 2, 1},
        {"ccc.exs", Mod, 3, :unspecified},
        {"ddd.exs", Mod, 4, 3}
      ])

    message =
      "ルートが一意に決定できません。\n" <>
        "新旧のマイグレーションファイルが混ざっている可能性があります。\n" <> "ルート候補:\n" <> "- bbb.exs\n" <> "- ddd.exs"

    assert {:error, [message]} == Yacto.Migration.Util.sort_migrations(input)

    input =
      make_migrations([
        {"aaa.exs", Mod, 1, 3},
        {"bbb.exs", Mod, 2, 1},
        {"ccc.exs", Mod, 3, 2}
      ])

    message = "マイグレーションファイルの指定が循環しています。"
    assert {:error, [message]} == Yacto.Migration.Util.sort_migrations(input)

    input =
      make_migrations([
        {"aaa.exs", Mod, 1, nil},
        {"bbb.exs", Mod, 2, :unspecified},
        {"ccc.exs", Mod, 3, 1}
      ])

    message = "用途不明のマイグレーションファイルが存在しています。\n- bbb.exs"
    assert {:error, [message]} == Yacto.Migration.Util.sort_migrations(input)

    input =
      make_migrations([
        {"aaa.exs", Mod, 1, :unspecified},
        {"bbb.exs", Mod, 2, :unspecified},
        {"ccc.exs", Mod, 3, 1}
      ])

    message = "旧バージョンのマイグレーションファイルの順序が間違っています。\n" <> "最新は aaa.exs であるはずなのに bbb.exs になっています。"
    assert {:error, [message]} == Yacto.Migration.Util.sort_migrations(input)
  end
end
