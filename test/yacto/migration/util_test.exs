defmodule Yacto.Migration.UtilTest do
  use PowerAssert

  test "マイグレーションディレクトリの確認" do
    expected = Path.join([File.cwd!(), "_build", "test", "lib", "yacto", "priv", "migrations"])
    assert expected == Yacto.Migration.Util.get_migration_dir(:yacto)

    expected = Path.join(["priv", "migrations"])
    assert expected == Yacto.Migration.Util.get_migration_dir_for_gen()
  end

  test "get_all_schema で全てのスキーマを取得できるか" do
    require Yacto.Migration.SchemaMigration
    assert Yacto.Migration.SchemaMigration in Yacto.Migration.Util.get_all_schema(:yacto)

    # prefix を付けて確認
    assert [Yacto.Migration.SchemaMigration] ==
             Yacto.Migration.Util.get_all_schema(:yacto, Yacto.Migration)

    assert [Yacto.Migration.SchemaMigration] ==
             Yacto.Migration.Util.get_all_schema(:yacto, Yacto.Migration.SchemaMigration)

    assert [] == Yacto.Migration.Util.get_all_schema(:yacto, FooBar)
  end

  describe "need_gen_migration?/1" do
    setup do
      Code.compiler_options(ignore_module_conflict: true)

      on_exit(fn ->
        Code.compiler_options(ignore_module_conflict: false)
      end)

      :ok
    end

    test "when an option 'migration: true' is passed to Yacto.Schema" do
      {:module, schema, _, _} =
        defmodule TestSchema do
          use Yacto.Schema, dbname: :default, migration: true
        end

      assert Yacto.Migration.Util.need_gen_migration?(schema)
    end

    test "when an option 'migration: false' is passed to Yacto.Schema" do
      {:module, schema, _, _} =
        defmodule TestSchema do
          use Yacto.Schema, dbname: :default, migration: false
        end

      refute Yacto.Migration.Util.need_gen_migration?(schema)
    end

    test "when an option 'migration' is NOT passed to Yacto.Schema" do
      {:module, schema, _, _} =
        defmodule TestSchema do
          use Yacto.Schema, dbname: :default, migration: false
        end

      refute Yacto.Migration.Util.need_gen_migration?(schema)
    end
  end
end
