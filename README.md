# Yacto

Yacto は、[Ecto](https://hexdocs.pm/ecto/Ecto.html) で使いにくかった部分をサポートするためのライブラリです。

大まかに以下の機能があります。

- マイグレーションファイルの自動生成
- 別アプリケーションからのマイグレーションの利用
- 水平分割したデータベースへのマイグレーション
- 複数データベースを跨るトランザクション（XA トランザクション）

## マイグレーションファイルの自動生成

Yacto は、特にマイグレーション周りが Ecto と異なります。
Ecto はスキーマとマイグレーションを別で定義していましたが、Yacto は **スキーマからマイグレーションファイルを自動的に出力します**。

具体的には、以下の様にスキーマを定義したとして、

lib/my_app/player.ex:

```elixir
defmodule MyApp.Player do
  use Yacto.Schema, dbname: :player

  schema @auto_source do
    # sharding key
    field :player_id, :string, meta: [null: false, size: 64]
    field :hp, :integer, default: 0, meta: [null: false]
    index :player_id, unique: true
  end
end
```

この状態で `mix yacto.gen.migration` を実行すると、以下の様なマイグレーションファイルが出力されます。

priv/migrations/2017-11-22T045225_my_app.exs:

```elixir
defmodule MyApp.Migration20171122045225 do
  use Ecto.Migration

  def change(MyApp.Player) do
    create table("my_app_player")
    alter table("my_app_player") do
      add(:hp, :integer, [null: false, size: 64])
      add(:player_id, :string, [null: false])
    end
    create index("my_app_player", [:player_id], [name: "player_id_index", unique: true])
  end

  def change(_other) do
    :ok
  end

  def __migration_structures__() do
    [
      {MyApp.Player, %Yacto.Migration.Structure{fields: [:id, :player_id, :hp], meta: %{attrs: %{hp: %{null: false}, player_id: %{null: false, size: 64}}, indices: %{{[:player_id], [unique: true]} => true}}, source: "my_app_player", types: %{hp: :integer, id: :id, player_id: :string}}},
    ]
  end

  def __migration_version__() do
    20171122045225
  end
end
```

あとは `mix yacto.migrate` を実行すれば、このマイグレーションファイルがデータベースに反映されます。
もうマイグレーションファイルを自分で記述する必要はありません。

更に、この状態で `MyApp.Player` スキーマに `:mp` フィールドを追加して `mix yacto.gen.migration` を実行すると、以下のマイグレーションファイルが生成されます。

lib/my_app/player.ex:

```elixir
defmodule MyApp.Player do
  ...

  schema @auto_source do
    ...

    # add a field
    field :mp, :integer, default: 0, meta: [null: false]

    ...
  end
end
```

priv/migrations/2017-11-22T045225_my_app.exs:

```elixir
defmodule MyApp.Migration20171122052212 do
  use Ecto.Migration

  def change(MyApp.Player) do
    alter table("my_app_player") do
      add(:mp, :integer, [null: false])
    end
  end

  def change(_other) do
    :ok
  end

  def __migration_structures__() do
    [
      {MyApp.Player, %Yacto.Migration.Structure{fields: [:id, :player_id, :hp, :mp], meta: %{attrs: %{hp: %{null: false}, mp: %{null: false}, player_id: %{null: false, size: 64}}, indices: %{{[:player_id], [unique: true]} => true}}, source: "my_app_player", types: %{hp: :integer, id: :id, mp: :integer, player_id: :string}}},
    ]
  end

  def __migration_version__() do
    20171122052212
  end
end
```

このように、以前からの差分だけがマイグレーションファイルに出力されます。
`mix yacto.migrate` を実行すれば、このマイグレーションファイルがデータベースに反映されます。

もしマイグレーションファイルが１つもデータベースに適用されていなかったら、上記の２つのマイグレーションファイルが順番に適用されます。

### 別アプリケーションからのマイグレーションの利用

先程作った `my_app` アプリケーションを利用する `other_app` アプリケーションがあったとします。
`my_app` はデータベース利用しているので、`other_app` 上で `my_app` のためのマイグレーションを行う必要があります。
Yacto を使えば、`config/config.exs` を適切に書いた後、`other_app` で以下のコマンドを実行するだけで `my_app` のマイグレーションができます。

```
mix yacto.migrate --app my_app
```

Ecto では、他のアプリケーションが必要としているマイグレーションを自分で書くか、各アプリケーションが指定したバラバラな方法でマイグレーションを行う必要がありました。
Yacto を使っているアプリケーションでは、全て同じ方法でマイグレーションができます。

### 水平分割したデータベースへのマイグレーション

例えば `MyApp.Player` スキーマを水平分割した場合、このスキーマのマイグレーションファイルを複数の Repo に適用する必要があります。
これは、設定ファイルに以下の様に書くだけで出来ます。

config/config.exs:

```elixir
config :yacto, :databases,
  %{
    default: %{
      module: Yacto.DB.Single,
      repo: MyApp.Repo.Default,
    },
    player: %{
      module: Yacto.DB.Shard,
      repos: [MyApp.Repo.Player0, MyApp.Repo.Player1],
    },
  }
```

`MyApp.Player` に以下のコードがあったことを思い出して下さい。

lib/my_app/player.ex:

```elixir
defmodule MyApp.Player do
  use Yacto.Schema, dbname: :player

  ...
```

この `:player` が、`MyApp.Player` が所属する Repo のグループ名です。
`MyApp.Player` は `:player` という Repo グループに所属しており、`:player` Repo グループは設定ファイルから `MyApp.Repo.Player0` と `MyApp.Repo.Player1` の Repo に紐付いていることが分かります。

設定ファイルを書いたら、あとは `mix yacto.migrate` を実行するだけです。
`MyApp.Player` のマイグレーションファイルが `MyApp.Repo.Player0` と `MyApp.Repo.Player1` に適用されます。

水平分割したデータベースを利用する時には、`Yacto.DB.repo/2` を使って Repo を取得します。

```elixir
repo = Yacto.DB.repo(:player, player_id)
MyApp.Player |> repo.all()
```

あるいは、`schema.repo/1` を使っても構いません。

```elixir
repo = MyApp.Player.repo(player_id)
MyApp.Player |> repo.all()
```

#### 他のアプリケーションから利用する

もちろん、この水平分割した `my_app` アプリケーションを `other_app` で利用することもできます。
`other_app` で以下の様に設定ファイル書いて、

config/config.exs:

```elixir
config :yacto, :databases,
  %{
    default: %{
      module: Yacto.DB.Single,
      repo: OtherApp.Repo.Default,
    },
    player: %{
      module: Yacto.DB.Shard,
      repos: [OtherApp.Repo.Player0, OtherApp.Repo.Player1, OtherApp.Repo.Player2],
    },
  }
```

`mix yacto.migrate --app my_app` を実行すると、`OtherApp.Repo.Player0` と `OtherApp.Repo.Player1` と `OtherApp.Repo.Player2` に `MyApp.Player` スキーマのマイグレーションファイルが適用されます。

### 複数データベースを跨るトランザクション（XA トランザクション）

`Yacto.transaction/2` を使うと、複数のデータベースを指定してトランザクションを発行できます。

```elixir
# ２つ以上の Repo が指定されているので XA トランザクションを発行する
Yacto.transaction([:default,
                   {:player, player_id1},
                   {:player, player_id2}], fn ->
  default_repo = Yacto.DB.repo(:default)
  player1_repo = Yacto.DB.repo(:player, player_id1)
  player2_repo = Yacto.DB.repo(:player, player_id2)

  # ここら辺でデータベースを操作する
  ...

# ここで全ての XA トランザクションがコミットされる
end)
```

以下の３つの Repo に対してトランザクションを行います。

- `:default` の Repo `MyApp.Repo.Default`
- `player_id1` でシャーディングされた Repo
- `player_id2` でシャーディングされた Repo

後ろの２つは、シャードキーによっては同じ Repo になる可能性があるので、利用する Repo は２つか３つのどちらかです。
２つ以上の Repo を利用してトランザクションを開始する場合、自動的に XA トランザクションになります。

XA トランザクションは確実に不整合が防げる訳ではありませんが、別々でトランザクションを発行するよりは防げます。
ただしこのライブラリでは `XA RECOVER` に残ったトランザクションを解決する仕組みを提供していないので、別途用意する必要があります。

## Yacto のスキーマ

Yacto のスキーマについて、まだ説明していない部分があるので、もう少し詳しく説明します。

最初に書いたように、Yacto のスキーマは以下の様に定義します。

```elixir
defmodule MyApp.Player do
  use Yacto.Schema, dbname: :player

  schema @auto_source do
    field :player_id, :string, meta: [null: false, size: 64]
    field :hp, :integer, default: 0, meta: [null: false]
    index :player_id, unique: true
  end
end
```

基本的には `Ecto.Schema` と変わりません。
`Yacto.Schema` で生成したスキーマは、`Ecto.Schema` で生成したスキーマと互換性があります。
ただしマイグレーションに関する設定が含まれるので、`Ecto.Schema` よりもいくつか設定が増えています。

### テーブル名の自動生成

`@auto_source` には、モジュール名から自動的に生成したテーブル名が定義されています。
大抵の場合、自動的に決まった名前で問題ないと思うので、常に `@auto_source` を使うので問題ないでしょう。

### メタ情報

```elixir
    field :player_id, :string, meta: [null: false, size: 64]
    field :hp, :integer, default: 0, meta: [null: false]
```

ここは `Ecto.Schema` の `field/3` 関数とほとんど同じですが、`:meta` オプションがあるという点で異なります。
`:meta` オプションはマイグレーションに関する情報を入れる場所で、そのフィールドが null 可能かどうかや、文字列のサイズ等を指定します。

指定可能なオプションは以下の通りです。

- `:null`: そのフィールドが null 可能かどうか（デフォルトでは `true`）
- `:size`: 文字列のサイズ（`VARCHAR(255)` の `255` に相当する部分）（デフォルトでは `255`）
- `:default`: そのフィールドのデフォルト値（デフォルトでは各型の初期値か、`opts[:default]` が存在している場合はその値が入る）
- `:index`: このフィールドでインデックスを張るかどうか（デフォルトでは `false`）
- `:type`: マイグレーション時の型を指定する（デフォルトでは `field/3` で指定した型）

### インデックス

```elixir
    index :player_id, unique: true
```

`index/2` でインデックスを生成できます。
`field/3` の `:meta` オプションの中でもインデックスを指定できますが、`index/2` を使うと複合インデックスやユニークインデックスも生成できます。

複合インデックスにするなら `index [:player_id, :hp]` のようにリストで指定します。
ユニークインデックスにするならオプションで `unique: true` を指定します。

### 外部キー制約

対応していません。
必要だと思ったのであれば、ぜひ実装して pull req 下さい。

## 便利関数

Yacto は、Repo に便利な関数を定義する `Yacto.Repo.Helper` を提供しています。

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app
  use Yacto.Repo.Helper
end
```

これによって、以下の関数が定義されます。

- `def count(queryable, clauses, opts \\ [])`

`Ecto.Query.where` で絞り込んで要素数を返します。

- `def find(queryable, clauses, opts \\ [])`

`Ecto.Query.where` で絞り込んで Repo から取得します。

- `def delete_by(queryable, clauses, opts \\ [])`
- `def delete_by!(queryable, clauses, opts \\ [])`

`Ecto.Query.where` で絞り込んで Repo から削除します。
`delete_by!/3` は、削除した件数が 0 だった時に `Ecto.NoResultsError` 例外を投げます。

- `def find_for_update(queryable, clauses, opts \\ [])`
- `get_for_update(queryable, id, opts \\ [])`
- `get_for_update!(queryable, id, opts \\ [])`
- `get_by_for_update(queryable, clauses, opts \\ [])`
- `get_by_for_update!(queryable, clauses, opts \\ [])`

`SELECT ... FOR UPDATE` のクエリを使って要素を取得する関数です。

`find_for_update/3` は `find/3` のクエリに `Ecto.Query.lock("FOR UPDATE")` を付けただけの関数です。
`get_for_update/3` や `get_by_for_update/3` 関数は、`Ecto.Repo.get` や `Ecto.Repo.get_by` のクエリに `Ecto.Query.lock("FOR UPDATE")` を付けただけの関数です。


- `get_by_or_new(queryable, clauses, default_struct, opts \\ [])`
- `get_by_or_insert_for_update(queryable, clauses, default_struct_or_changeset, opts \\ [])`

`get_by_or_new/4` は、まずレコードを取得してみて、あればそのレコードを、無ければデフォルト値 `default_struct` を返します。無かった場合でもデータベースへの挿入は行いません。
ロックを取らないので、この `get_by_or_new/4` で得られた値を使ってデータベースへ挿入や更新をしてはいけません。
戻り値は `{record, defaulted}` の２要素のタプルになっていて、1要素目には取得できたレコード（あるいはデフォルト値）が、2要素目にはデフォルト値を返したかどうかのフラグが設定されます。

`get_by_or_insert_for_update/4` は、`get_by_or_new/4` の排他ロックを取るバージョンです。
まずレコードを取得してみて、あればそのレコードを、無ければ新規に `default_struct_or_changeset` を挿入して返します。この時、返されるレコードは排他ロックされます。
戻り値は `{record, created}` の２要素のタプルになっていて、1要素目には取得できたレコード（あるいは挿入したデフォルト値）が、2要素目には新しく挿入したかどうかのフラグが設定されます。
