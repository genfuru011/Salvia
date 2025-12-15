# Sage ドキュメント

Sageは、Rubyの優雅さとDeno/TypeScriptのモダンなエコシステムを組み合わせた、軽量で高性能なフルスタックフレームワークです。

## 目次

1. [アーキテクチャ](#1-アーキテクチャ)
2. [ディレクトリ構造](#2-ディレクトリ構造)
3. [ルーティングとリソース](#3-ルーティングとリソース)
4. [フロントエンド統合 (Deno & Islands)](#4-フロントエンド統合-deno--islands)
5. [データベース (ActiveRecord)](#5-データベース-activerecord)
6. [ミドルウェア](#6-ミドルウェア)
7. [CLIコマンド](#7-cliコマンド)

---

## 1. アーキテクチャ

Sageは **"Sage Native Architecture"** と呼ばれる独自の構成を採用しています。

*   **Ruby (Backend)**: "Dumb Pipe"（土管）として機能し、ルーティング、データベース操作、認証などのビジネスロジックを担当します。
*   **Deno (Sidecar)**: "View Engine" として機能し、SSR (Server-Side Rendering)、アセットのオンデマンドコンパイル、クライアントサイドのハイドレーションを担当します。
*   **通信**: RubyとDenoはUnixドメインソケット上のHTTPで通信します。

### 処理の流れ

1.  **SSRリクエスト**: Rubyが `ctx.render` を呼び出すと、DenoサイドカーにRPCリクエストを送り、レンダリングされたHTMLを受け取ってブラウザに返します。
2.  **アセットリクエスト**: ブラウザからの `/assets/*` へのリクエストは、RubyのミドルウェアがDenoにプロキシし、DenoがTypeScriptをオンデマンドでコンパイルして返します。

---

## 2. ディレクトリ構造

```text
my_app/
├── app/
│   ├── models/        # ActiveRecordモデル
│   ├── pages/         # ページコンポーネント (SSRのエントリーポイント)
│   ├── components/    # 再利用可能なコンポーネント
│   ├── islands/       # クライアントサイドで動作するIslandsコンポーネント
│   └── resources/     # リソース (コントローラー)
├── config/
│   ├── application.rb # アプリケーション設定
│   └── database.rb    # データベース設定
├── public/            # 静的ファイル
├── deno.json          # フロントエンドの依存関係管理
└── Gemfile            # Rubyの依存関係管理
```

---

## 3. ルーティングとリソース

SageはRailsに似たリソースベースのルーティングを採用しています。

### リソースの定義 (`app/resources/todos_resource.rb`)

```ruby
class TodosResource < Sage::Resource
  # GET /todos
  get "/" do |ctx|
    todos = Todo.all
    # app/pages/Todos.tsx をレンダリング
    ctx.render "Todos", todos: todos
  end

  # POST /todos
  post "/" do |ctx|
    Todo.create(title: ctx.params[:title])
    ctx.redirect "/todos"
  end
  
  # GET /todos/:id
  get "/:id" do |ctx, id|
    todo = Todo.find(id)
    ctx.render "Todo", todo: todo
  end
end
```

### ルーティングの設定 (`config/application.rb`)

```ruby
class App < Sage::Base
  mount "/", HomeResource
  mount "/todos", TodosResource
end
```

---

## 4. フロントエンド統合 (Deno & Islands)

Sageは **Islands Architecture** を採用しており、静的なHTMLの中にインタラクティブな部分（Island）を埋め込むことができます。

### ページ (`app/pages/`)

サーバーサイドでのみレンダリングされる静的なコンポーネントです。

```tsx
// app/pages/Home.tsx
import { h } from "preact";
import Counter from "../islands/Counter.tsx";

export default function Home() {
  return (
    <div>
      <h1>Welcome</h1>
      {/* Islandコンポーネントの使用 */}
      <Counter />
    </div>
  );
}
```

### Islands (`app/islands/`)

クライアントサイドでJavaScriptとして実行されるインタラクティブなコンポーネントです。ファイルの先頭に `"use hydration";` を記述します。

```tsx
// app/islands/Counter.tsx
"use hydration";
import { h } from "preact";
import { useState } from "preact/hooks";

export default function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

### 依存関係の管理 (`deno.json`)

npmパッケージは `deno.json` で管理します。SSRとブラウザの両方で自動的に解決されます。

```json
{
  "imports": {
    "preact": "npm:preact@10.19.6",
    "canvas-confetti": "npm:canvas-confetti@1.9.2"
  }
}
```

---

## 5. データベース (ActiveRecord)

標準でActiveRecordをサポートしています。

### 設定 (`config/database.rb`)

```ruby
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "db/development.sqlite3"
)
```

### モデル (`app/models/todo.rb`)

```ruby
class Todo < ActiveRecord::Base
end
```

---

## 6. ミドルウェア

Rackミドルウェアを標準でサポートしています。

```ruby
class App < Sage::Base
  use Rack::Session::Cookie, secret: "secret"
  use MyCustomMiddleware
end
```

---

## 7. CLIコマンド

| コマンド | 説明 |
|---------|------|
| `sage new <name>` | 新しいSageプロジェクトを作成します |
| `sage dev` | 開発サーバーを起動します（ホットリロード有効） |
| `sage server` | 本番用サーバーを起動します |
