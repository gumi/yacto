# 変更履歴

- UPDATE
    - 下位互換がある変更
- ADD
    - 下位互換がある追加
- CHANGE
    - 下位互換のない変更
- FIX
    - バグ修正

## 2.0.0-rc.1

### 下位互換のない変更

- [CHANGE] マイグレーションファイルをモデル毎に生成する
  - 今まで生成した全てのマイグレーションファイルは利用できなくなります。
  - 新しく生成したマイグレーションファイルで `mix yacto.migrate --fake` を実行して新しくマイグレーションスキーマを設定する必要があります。
- [CHANGE] `Yacto.Schema` で定義していたデフォルトの `@primary_key` を削除した
- [CHANGE] `@auto_source` から生成するテーブル名のルールを変更した
  - 例えば `App.Model.FooBar` の場合、1.x では `app_model_foo_bar` になっていたが、2.x では `app_model_foobar` となる
- [CHANGE] `Yacto.DB` の引数にキーワードリストを取れるようにして、データベースの設定を動的に渡せるようにした
  - `Yacto.DB.repo(:player, "key")` と書いていたのを `Yacto.DB.repo(:player, shard_key: "key")` と書く必要がある
- [CHANGE] `:table_name_converter` は不完全な機能だったので削除した
- [CHANGE] `Yacto.Schema.Single` と `Yacto.Schema.Shard` を削除した
  - データベースの設定を動的に渡せるようになり、`Yacto.Schema.Single` と `Yacto.Schema.Shard` のチェック機構が使えなくなるため。
- [CHANGE] `mix yacto.migrate` で `--repo` を指定しなかった場合に利用するリポジトリ一覧を `:ecto_repos` から取得するようにした

### 下位互換がある追加

- [ADD] スキーマの定義時にマイグレーションファイルを生成するかどうかを選択できるようにした（Thanks @mori5321 !）
- [ADD] `field/3` のマイグレーション用メタ情報に `:precision` と `:scale` を追加
- [ADD] モデルを削除した時に drop table する機能を実装
- [ADD] マイグレーションファイルを検証する機能を実装
  - 複数のブランチからマージした場合に矛盾が起きる可能性があったので、それを検出してエラーにする
- [ADD] `Yacto.transaction/3` に、XA を行わない `:noxa` オプションを追加した

### 下位互換がある変更

- [UPDATE] Ecto 3.4 への対応
  - MySQL Adapter をやめて MyXQL Adapter を使うようにした
  - 新しいバージョンの Ecto.Migration.Runner に追従
- [UPDATE] Elixir 1.10 への対応
- [UPDATE] 全体的に日本語でやることにした

### バグ修正

- [FIX] インデックスの付いたフィールドを削除するとマイグレーションに失敗する問題を修正した (Thanks @h1u2i3 !)
- [FIX] DB の新規作成時に、カラムの並びが定義順になるようにした
- [FIX] `:index_name_max_length` 設定がある場合、長いインデックス名を削るようにした
- [FIX] `get_for_update/3` を修正した
- [FIX] テスト周りのリファクタリング

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
