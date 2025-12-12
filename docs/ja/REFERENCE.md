# Salvia リファレンスガイド

このガイドは、Ruby on Rails アプリケーションで Salvia を使用するための包括的なリファレンスです。

## 1. インストール

Salvia を Rails アプリケーションに追加するには:

1.  **Deno をインストールします** (必須):
    ```bash
    curl -fsSL https://deno.land/x/install/install.sh | sh
    ```

2.  `Gemfile` に gem を追加します:
    ```ruby
    gem 'salvia'
    ```

3.  gem をインストールします:
    ```bash
    bundle install
    ```

4.  Salvia インストーラーを実行します:
    ```bash
    bundle exec salvia install
    ```

これにより、以下の処理が行われます:
*   `salvia/` ディレクトリ構造の作成
*   `deno.json` (依存関係の SSOT) の生成
*   **Deno 依存関係のキャッシュ** (初回起動の高速化)
*   Rails 設定の更新 (`Salvia::Helpers` の注入)

## 2. ディレクトリ構造

Salvia は、フロントエンドの関心事を分離するために、Rails プロジェクトのルートに専用の `salvia/` ディレクトリを導入します。

```
my_app/
├── app/                   # Rails バックエンド
│   ├── controllers/
│   └── ...
├── salvia/                # フロントエンドルート
│   ├── app/
│   │   ├── components/    # 共有 UI コンポーネント (ステートレス)
│   │   ├── islands/       # インタラクティブなクライアントコンポーネント (ハイドレーション)
│   │   └── pages/         # サーバーコンポーネント (SSR のみ)
│   └── deno.json          # 依存関係管理 (Import Map)
└── public/
    └── assets/            # コンパイル済みアセット (本番環境用)
```

*   **`salvia/app/pages/`**: ビューのエントリーポイントです。これらは Rails のビューに対応しますが、TSX で記述されます。サーバー上でレンダリングされ、HTML として送信されます。
*   **`salvia/app/islands/`**: クライアント上で JavaScript を必要とするインタラクティブなコンポーネントです。これらは自動的に「ハイドレーション」されます。
*   **`salvia/app/components/`**: Pages と Islands の両方で使用できる再利用可能な UI パーツ（ボタン、カード、レイアウト）です。

## 3. コアコンセプト

### サーバーコンポーネント (Pages)
*   **場所**: `salvia/app/pages/`
*   **動作**: サーバー上で HTML にレンダリングされます。これらのコンポーネントの JavaScript はクライアントに送信されません。
*   **用途**: レイアウト、静的コンテンツ、初期データの表示。

```tsx
// salvia/app/pages/home/Index.tsx
import { h } from 'preact';

export default function Home({ title }) {
  return <h1>{title}</h1>;
}
```

### クライアントコンポーネント (Islands)
*   **場所**: `salvia/app/islands/`
*   **動作**: サーバー上で HTML にレンダリングされた後、クライアント上で「ハイドレーション」されてインタラクティブになります。
*   **用途**: カウンター、フォーム、ドロップダウンなどのインタラクティブな要素。

```tsx
// salvia/app/islands/Counter.tsx
import { h } from 'preact';
import { useState } from 'preact/hooks';

export default function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

### 共有コンポーネント (Shared Components)
*   **場所**: `salvia/app/components/`
*   **動作**: Pages と Islands の両方からインポートできます。
*   **用途**: デザインシステムコンポーネント。

## 4. ルーティングとレンダリング

Salvia は標準の Rails ルーティングとコントローラーに依存しています。

### `ssr` ヘルパー

Rails コントローラーから Salvia Page をレンダリングするには、`ssr` ヘルパーメソッドを使用します。

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.all
    # salvia/app/pages/posts/Index.tsx をレンダリング
    render html: ssr("posts/Index", posts: @posts)
  end
end
```

*   **第1引数**: `salvia/app/pages/` からの相対パスでコンポーネントを指定します。
*   **第2引数**: コンポーネントに渡す props のハッシュです。

## 5. データフロー

### Props (サーバー -> クライアント)
データは Rails コントローラーから Page へ、そして Props を介して Islands へと流れます。

```ruby
# Controller
render html: ssr("Show", user: @user)
```

```tsx
// Page (Server Component)
export default function Show({ user }) {
  return (
    <div>
      <h1>{user.name}</h1>
      {/* データを Island に渡す */}
      <EditProfileForm user={user} />
    </div>
  );
}
```

### Signals (クライアント状態)
クライアントサイドの状態管理には、Salvia は **Preact Signals** を推奨しています。

```tsx
import { signal } from "@preact/signals";

const count = signal(0);

export default function Counter() {
  return <button onClick={() => count.value++}>{count}</button>;
}
```

## 6. Turbo 統合

Salvia は、複雑なクライアントサイドルーティングなしで SPA のようなナビゲーションを実現するために、Turbo Drive と連携するように設計されています。

### セットアップ
レイアウト（例: `salvia/app/pages/layouts/Main.tsx`）で Turbo が読み込まれていることを確認してください。

```tsx
<head>
  <script type="module">
    import * as Turbo from "https://esm.sh/@hotwired/turbo@8.0.0";
    Turbo.start();
  </script>
</head>
```

### Turbo Streams
Rails コントローラーから Turbo Stream レスポンスを返して、ページの一部を動的に更新することができます。

```ruby
def create
  @comment = Comment.create(params[:comment])
  render turbo_stream: turbo_stream.append("comments", html: ssr("components/Comment", comment: @comment))
end
```

## 7. デプロイ

本番環境では、JavaScript アセットと CSS をビルドする必要があります。

```bash
bundle exec salvia build
```

このコマンドは以下の処理を行います:
1.  `salvia/app/islands/` をスキャンしてインタラクティブなコンポーネントを探します。
2.  それらを `public/assets/islands/` にバンドルします (**ハッシュ付きファイル名**)。
3.  本番用の Import Map (`manifest.json`) を生成します。
4.  **Tailwind CSS をビルドします** (`bin/rails tailwindcss:build` を実行)。

デプロイプロセス（例: Dockerfile や CI/CD パイプライン）の中でこのコマンドを実行するようにしてください。

## 8. 設定 (deno.json)

Salvia v0.2.0 以降、`salvia/deno.json` が依存関係の唯一の信頼できる情報源 (SSOT) です。

### 依存関係の追加
`imports` セクションに追加します。`npm:` 指定子は自動的に `esm.sh` に変換されます。

```json
{
  "imports": {
    "uuid": "npm:uuid@9.0.0"
  }
}
```

### グローバル変数の拡張 (SSR)
SSR 環境で特定のライブラリをグローバル変数として公開したい場合 (例: `uuid` など)、`salvia.globals` を使用します。

```json
{
  "salvia": {
    "globals": {
      "uuid": "globalThis.UUID"
    }
  }
}
```
