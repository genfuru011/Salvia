# Salvia.rb Architecture

> フレームワークの内部構造と設計思想

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        HTTP Request                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Rack Middleware                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Rack::Static│  │Rack::Session│  │ (Future: CSRF etc.) │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Salvia::Application                        │
│                    (Rack App Entry)                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Salvia::Router                           │
│              ┌────────────────────────┐                      │
│              │   Route Matching       │                      │
│              │   (Mustermann)         │                      │
│              └────────────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Salvia::Controller                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐  │
│  │  params  │  │  render  │  │ redirect │  │ htmx_request│  │
│  └──────────┘  └──────────┘  └──────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    View Rendering                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Tilt + Erubi (ERB)                      │   │
│  │  ┌────────────┐  ┌────────────┐  ┌───────────────┐  │   │
│  │  │   Layout   │  │  Template  │  │    Partial    │  │   │
│  │  └────────────┘  └────────────┘  └───────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       HTML Response                          │
│                  (+ HTMX for partial updates)                │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Salvia::Application

**役割:** Rack アプリケーションのエントリーポイント

```ruby
# lib/salvia_rb/application.rb
class Application
  def call(env)
    request = Rack::Request.new(env)
    response = Rack::Response.new

    handle_request(request, response)  # → Router → Controller
    response.finish
  end
end
```

**責務:**
- Rack インターフェースの実装 (`call(env)`)
- Router への dispatch
- エラーハンドリング（開発/本番）
- 404/500 ページの生成

---

### 2. Salvia::Router

**役割:** URL パターンマッチングとコントローラーへのルーティング

```ruby
# lib/salvia_rb/router.rb
Router.draw do
  root to: "home#index"
  get "/posts/:id", to: "posts#show"
  resources :comments
end
```

**設計ポイント:**

| 項目 | 実装 |
|------|------|
| パターンマッチ | Mustermann (`:rails` type) |
| DSL | `root`, `get`, `post`, `resources` |
| シングルトン | `Router.instance` でグローバルアクセス |
| ルート構造 | `Route` Struct (method, pattern, controller, action) |

**ルート解決フロー:**
```
1. request.request_method + request.path_info を取得
2. 登録されたルートを順番に走査
3. Mustermann.match? でパターンマッチ
4. マッチしたら [ControllerClass, action, params] を返す
```

---

### 3. Salvia::Controller

**役割:** リクエスト処理とレスポンス生成

```ruby
# lib/salvia_rb/controller.rb
class PostsController < Salvia::Controller
  def show
    @post = Post.find(params["id"])
    render "posts/show"
  end
end
```

**主要メソッド:**

| メソッド | 説明 |
|----------|------|
| `params` | URL パラメータ + クエリ/ボディパラメータの統合 |
| `render(template, locals:, layout:, status:)` | ERB テンプレートのレンダリング |
| `render_partial(template, locals:)` | パーシャルのレンダリング（レイアウトなし） |
| `redirect_to(url, status:)` | リダイレクト（HTMX 対応） |
| `htmx_request?` | HTMX リクエスト判定 |
| `htmx_trigger(event, detail)` | HTMX イベントトリガー |

---

### 4. Smart Rendering（HTMX 推奨、オプショナル）

**コンセプト:** HTMX リクエストを自動判定してレイアウトの有無を切り替え（HTMX がなくても動作）

```
┌──────────────────────────────────────────────────────────┐
│                    render("posts/show")                   │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │   htmx_request?         │
              │   (HX-Request header)   │
              └─────────────────────────┘
                     │           │
                    YES          NO
                     │           │
                     ▼           ▼
          ┌──────────────┐  ┌──────────────────┐
          │ Partial Only │  │ Layout + Content │
          │ (no layout)  │  │ (full page)      │
          └──────────────┘  └──────────────────┘
```

**判定ロジック:**
```ruby
def determine_layout(layout_option, template)
  return false if layout_option == false          # 明示的に無効化
  return false if template.start_with?("_")       # パーシャル
  return false if htmx_request?                   # HTMX リクエスト
  layout_option || default_layout                 # デフォルトレイアウト
end
```

---

### 5. Salvia::Database

**役割:** ActiveRecord の接続管理

```ruby
# lib/salvia_rb/database.rb
Database.setup!      # 接続確立
Database.migrate!    # マイグレーション実行
Database.create!     # DB 作成
Database.drop!       # DB 削除
```

**対応アダプタ:**
- SQLite3 (デフォルト)
- PostgreSQL
- MySQL

---

### 6. CLI (Thor)

**役割:** コマンドラインインターフェース

```
salvia
├── new APP_NAME      # アプリ生成
├── server (s)        # サーバー起動
├── console (c)       # IRB 起動
├── db:create         # DB 作成
├── db:drop           # DB 削除
├── db:migrate        # マイグレーション
├── db:rollback       # ロールバック
├── db:setup          # create + migrate
├── css:build         # Tailwind ビルド
├── css:watch         # Tailwind ウォッチ
├── routes            # ルート一覧
└── version           # バージョン表示
```

---

## Design Principles

### 1. 明示性 > 暗黙性

Rails の「設定より規約」とは異なり、Salvia は明示的な記述を重視します：

```ruby
# Salvia: 明示的に render を呼ぶ
def index
  @posts = Post.all
  render "posts/index"  # 明示的
end
```

### 2. シンプルさ > 機能性

- メタプログラミングを最小限に
- コードを読めば動作がわかる
- 「魔法」より「理解しやすさ」

### 3. HTML ファースト

- JSON API ではなく HTML を返す
- HTMX で部分更新
- SPA の複雑さを避ける

### 4. 依存の最小化

| 依存 | 用途 | 理由 |
|------|------|------|
| rack | HTTP 抽象化 | 標準的な Ruby Web インターフェース |
| mustermann | ルーティング | Sinatra で実績あり |
| tilt + erubi | テンプレート | 軽量で高速 |
| activerecord | ORM | Ruby のデファクトスタンダード |
| thor | CLI | 使いやすい CLI DSL |
| zeitwerk | オートローダー | Rails 標準、信頼性高 |
| tailwindcss-ruby | CSS | Node.js 不要 |

---

## Gem ソースコード構造 (salvia_rb/)

```
salvia_rb/
├── exe/
│   └── salvia                    # CLI エントリーポイント
├── lib/
│   ├── salvia_rb.rb              # メインモジュール（依存関係の読み込み）
│   └── salvia_rb/
│       ├── version.rb            # バージョン定義
│       ├── router.rb             # ルーティング DSL（Mustermann）
│       ├── controller.rb         # コントローラー基底クラス
│       ├── application.rb        # Rack アプリケーション
│       ├── database.rb           # ActiveRecord 接続管理
│       └── cli.rb                # Thor CLI（コマンド定義 + テンプレート生成）
├── salvia_rb.gemspec             # Gem 定義（依存関係）
├── Gemfile                       # 開発用依存関係
├── Rakefile                      # Gem ビルド/テストタスク
├── README.md                     # Gem ドキュメント
└── LICENSE.txt                   # MIT ライセンス
```

### 各ファイルの役割

| ファイル | 行数 | 役割 |
|----------|------|------|
| `cli.rb` | ~500 | アプリ生成、サーバー起動、DB/CSS コマンド |
| `controller.rb` | ~180 | Smart Rendering、render、params、HTMX ヘルパー |
| `router.rb` | ~120 | DSL ルーティング、Mustermann パターンマッチ |
| `database.rb` | ~120 | ActiveRecord 接続、マイグレーション管理 |
| `application.rb` | ~170 | Rack アプリ、エラーハンドリング、404/500 |
| `salvia_rb.rb` | ~50 | モジュール設定、依存関係読み込み |

---

## 生成されるアプリの構造 (Generated App)

```
myapp/
├── app/
│   ├── controllers/           # コントローラー
│   │   ├── application_controller.rb
│   │   └── posts_controller.rb
│   ├── models/                # ActiveRecord モデル
│   │   ├── application_record.rb
│   │   └── post.rb
│   └── views/                 # ERB テンプレート
│       ├── layouts/
│       │   └── application.html.erb
│       └── posts/
│           ├── index.html.erb
│           ├── show.html.erb
│           └── _post.html.erb  # パーシャル
├── config/
│   ├── database.yml           # DB 設定
│   ├── environment.rb         # 初期化
│   └── routes.rb              # ルーティング
├── db/
│   └── migrate/               # マイグレーションファイル
├── public/
│   └── assets/
│       ├── javascripts/
│       │   └── htmx.min.js
│       └── stylesheets/
│           └── tailwind.css
├── config.ru                  # Rack 設定
├── Gemfile
├── Rakefile
└── tailwind.config.js
```

---

## Request Lifecycle

```
1. HTTP Request arrives
   └─▶ config.ru
       └─▶ Rack::Static (静的ファイル)
       └─▶ Rack::Session (セッション)
       └─▶ Salvia::Application#call

2. Routing
   └─▶ Salvia::Router.recognize(request)
       └─▶ Mustermann pattern matching
       └─▶ Returns [ControllerClass, action, params]

3. Controller Processing
   └─▶ controller = ControllerClass.new(request, response, params)
   └─▶ controller.process(action)
       └─▶ Before actions (future)
       └─▶ Action method
       └─▶ render / redirect_to

4. View Rendering
   └─▶ Tilt.new(template_path)
   └─▶ template.render(self, locals)
   └─▶ Layout wrapping (unless HTMX/partial)

5. Response
   └─▶ response.finish
   └─▶ [status, headers, body]
```

---

## Future Architecture (Planned)

### Phase 1: Zeitwerk Integration
```ruby
# Auto-loading with Zeitwerk
loader = Zeitwerk::Loader.new
loader.push_dir("app/controllers")
loader.push_dir("app/models")
loader.setup
loader.eager_load  # Production
```

### Phase 2: Middleware Stack
```ruby
# Configurable middleware
Salvia.configure do |config|
  config.middleware.use Rack::Protection
  config.middleware.use Rack::Deflater
end
```

### Phase 3: Islands Architecture
```erb
<!-- Hydrate React components in ERB -->
<%= island "Counter", { initial: 0 } %>
```

---

## Comparison with Other Frameworks

| Feature | Salvia | Rails | Sinatra | Hanami |
|---------|--------|-------|---------|--------|
| Size | Tiny | Large | Tiny | Medium |
| Learning Curve | Low | High | Low | Medium |
| HTMX Support | Built-in | Addon | Manual | Manual |
| ORM | ActiveRecord | ActiveRecord | Choice | ROM |
| Auto-loading | Zeitwerk | Zeitwerk | Manual | Zeitwerk |
| Node.js Required | No | Optional | No | Optional |

---

*最終更新: 2025-01*

