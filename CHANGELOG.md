# Changelog

## 2.0.0-pre.14

- スキーマの定義時にマイグレーションファイルを生成するかどうかを選択できるようにした（Thanks @mori5321 !）

## 2.0.0-pre.13

- Elixir 1.9.0 の対応 (Thanks @hiromoon !)
- ecto_sql 3.1.6 への対応
  - MySQL Adapter をやめて MyXQL Adapter を使うようにした
  - 新しいバージョンの Ecto.Migration.Runner に追従

## 2.0.0-pre.12

- インデックスの付いたフィールドを削除するとマイグレーションに失敗する問題を修正した (Thanks @h1u2i3 !)

## 2.0.0-pre.11

- DB の新規作成時に、カラムの並びが定義順になるようにした

## 2.0.0-pre.10

- `field/3` のマイグレーション用メタ情報に `:precision` と `:scale` を追加

## 2.0.0-pre.9

- モデルを削除した時に drop table する機能を実装

## 2.0.0-pre.8

- マイグレーションファイルを検証する機能を実装
  - 複数のブランチからマージした場合に矛盾が起きる可能性があったので、それを検出してエラーにする
- 全体的に日本語でやることにした

## 2.0.0-pre.7

- Update dependencied

## 2.0.0-pre.6

- Shrink index name if configured

## 2.0.0-pre.5

- Update dependencies

## 2.0.0-pre.4

- Fix `get_for_update/3`

## 2.0.0-pre.3

- Update dependencies

## 2.0.0-pre.2

- Add `:noxa` option for `Yacto.transaction/3`

## 2.0.0-pre.1

- Using Ecto 3.0.0-rc.1
- Using Elixir 1.7
- Update dependencies

## 2.0.0-pre.0

### Breaking Changes

- Remove default `@primary_key` in `Yacto.Schema`
- Change convertion rule `@auto_source`
  - `App.Model.FooBar`: `app_model_foo_bar` in 1.x, `app_model_foobar` in 2.x.

## 1.2.6

- Implement table name converter

## 1.2.5

- Use asdf
- Fix migration error when using custom Ecto.Type with default value

## 1.2.4

- Customize a hashing function for sharding databases

## 1.2.3

- Fix a migration error is occured when using `:source` in field

## 1.2.2

- `timestamps/1` can be had `:meta`

## 1.2.1

- Fix an issue where using `autogenerate: {m, f, a}` in `@primary_key` definition causes an error
- Implement `@primary_key_meta` that specify a primary key meta info for migration

## 1.2.0

- Implement `Yacto.XA.rollback/2`

## 1.1.3

- Update dependencies

## 1.1.2

- In `Yacto.Schema.field/3`, if opts[:default] is specified, set the value to meta[:default]

## 1.1.1

- Rename `get_or_new/4` to `get_by_or_new/4` and `get_or_insert_for_update/4` to `get_by_or_insert_for_update/4`

## 1.1.0

- Add `Yacto.Schema.Single` and `Yacto.Schema.Shard` modules.
    - These define `repo/{0-1}` after `use Yacto.Schema`.
- Add `Yacto.Repo.Helper` to provide convenient functions.

## 1.0.7

- Apply elixir formatter
- Fix warnings
- Update dependencies

## 1.0.6

- [Bug] Fix a migration type name includes with spaces.

## 1.0.5

- Shorten index name for too long name error.
- Use specified migration type if :type defined in meta
- Remove illegal character in filename for Windows
