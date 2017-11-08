defmodule Yacto.Migration.UtilTest do
  use PowerAssert

  defp test_apply_myers_difference(list1, list2) do
    assert list2 == Yacto.Migration.Util.apply_myers_difference(list1, List.myers_difference(list1, list2))
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
    assert Path.join([File.cwd!(), "_build", "test", "lib", "yacto", "priv", "migrations"]) == Yacto.Migration.Util.get_migration_dir(:yacto)
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
    assert path1 == Yacto.Migration.Util.get_migration_path(:yacto, 12341234123456)
    assert path2 == Yacto.Migration.Util.get_migration_path(:yacto, 56785678567890)
    _ = File.rm_rf(dir)
  end

  test "get_all_schema" do
    require Yacto.Migration.SchemaMigration
    assert Yacto.Migration.SchemaMigration in Yacto.Migration.Util.get_all_schema(:yacto)
    assert [Yacto.Migration.SchemaMigration] == Yacto.Migration.Util.get_all_schema(:yacto, Yacto.Migration)
    assert [Yacto.Migration.SchemaMigration] == Yacto.Migration.Util.get_all_schema(:yacto, Yacto.Migration.SchemaMigration)
    assert [] == Yacto.Migration.Util.get_all_schema(:yacto, FooBar)
  end
end
