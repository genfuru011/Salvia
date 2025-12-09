# Salvia.rb リファレンスガイド

> 🌿 Salvia.rb v0.1.0 公式リファレンス

---

## 目次

1. [インストール](#インストール)
2. [設定](#設定)
3. [CLIコマンド](#cliコマンド)
4. [ルーティング](#ルーティング)
5. [コントローラー](#コントローラー)
6. [ビュー](#ビュー)
7. [ヘルパー](#ヘルパー)
8. [SSR Islands](#ssr-islands)
9. [データベース](#データベース)
10. [テスト](#テスト)
11. [デプロイ](#デプロイ)

---

## インストール

### Gem のインストール

```bash
gem install salvia_rb
```

### Bundler での使用

```ruby
# Gemfile
gem "salvia_rb"
```

### 必要条件

- Ruby 3.1+
- Deno（SSR ビルド用）
- SQLite3（デフォルト）または PostgreSQL/MySQL

---

## 設定

### ゼロコンフィグ起動

Salvia は設定なしで動作します：

```ruby
# config.ru（3行のみ！）
require "salvia_rb"
Salvia.configure { |c| c.root = __dir__ }
run Salvia::Application.new
```

### ワンライナー起動

```ruby
# app.rb
require "salvia_rb"
Salvia.run!  # 自動でサーバー選択: Puma (dev) or Falcon (prod)
```

### 設定オプション

```ruby
# config/environment.rb または config.ru
require "salvia_rb"

Salvia.configure do |config|
  # SSR Islands 設定
  config.ssr_bundle_path = "vendor/server/ssr_bundle.js"
  config.island_inspector = nil  # nil = auto (開発のみ有効)

  # データベース設定
  config.database_url = nil  # nil = database.yml または規約ベース

  # セッション設定
  config.session_secret = nil  # nil = 環境変数または自動生成
  config.session_key = nil     # nil = "_#{app_name}_session"

  # サーバー設定
  config.default_server = nil  # nil = dev: puma, prod: falcon

  # Autoload 追加パス
  config.autoload_paths = []

  # ログレベル
  config.log_level = nil  # nil = dev: debug, prod: info

  # セキュリティ設定
  config.csrf_enabled = true
  config.static_files_enabled = true
end

run Salvia::Application.new
```

### Configuration クラス API

| オプション | デフォルト | 説明 |
|-----------|-----------|------|
| `ssr_bundle_path` | `vendor/server/ssr_bundle.js` | SSR バンドルファイルのパス |
| `island_inspector` | `nil` (auto) | Island Inspector の有効/無効 |
| `database_url` | `nil` | データベース URL |
| `session_secret` | `nil` (auto) | セッション暗号化キー |
| `session_key` | `nil` (auto) | セッション Cookie 名 |
| `default_server` | `nil` (auto) | デフォルトサーバー |
| `autoload_paths` | `[]` | 追加の autoload パス |
| `log_level` | `nil` (auto) | ログレベル |
| `csrf_enabled` | `true` | CSRF 保護の有効化 |
| `static_files_enabled` | `true` | 静的ファイル配信の有効化 |

### 環境変数

Salvia は `.env` ファイルを自動で読み込みます：

```bash
# 読み込み順序（後のファイルが優先）:
# 1. .env                    - デフォルト値
# 2. .env.local              - ローカル上書き (gitignore)
# 3. .env.{RACK_ENV}         - 環境固有 (.env.production)
```

```bash
# .env.example
RACK_ENV=development
SESSION_SECRET=your-secret-here
DATABASE_URL=sqlite3:db/development.sqlite3
```

### 環境メソッド

```ruby
Salvia.env           # => "development"
Salvia.development?  # => true
Salvia.production?   # => false
Salvia.test?         # => false
Salvia.root          # => "/path/to/app"
Salvia.logger        # => Logger インスタンス
```

---

## CLIコマンド

### アプリケーション生成

```bash
# 新規アプリ作成（対話式）
salvia new APP_NAME

# オプション指定
salvia new APP_NAME --template=full --islands
salvia new APP_NAME --template=api --skip-prompts
salvia new APP_NAME --template=minimal
```

**テンプレートオプション:**
- `full` - フルスタック（ERB + Database + Views）
- `api` - API のみ（JSON レスポンス、ビューなし）
- `minimal` - 最小構成（ベア Rack アプリ）

### コード生成

```bash
# コントローラー生成
salvia generate controller NAME [actions]
salvia g controller posts index show create

# モデル生成
salvia g model NAME [fields]
salvia g model post title:string body:text published:boolean

# マイグレーション生成
salvia g migration NAME [fields]
salvia g migration add_user_id_to_posts user_id:integer
```

### 開発サーバー

```bash
# サーバー起動
salvia server
salvia s
salvia s -p 3000 -b 0.0.0.0

# 開発モード（サーバー + CSS + SSR ウォッチ）
salvia dev
salvia dev -p 3000

# コンソール
salvia console
salvia c
```

### データベース

```bash
salvia db:create      # データベース作成
salvia db:drop        # データベース削除
salvia db:migrate     # マイグレーション実行
salvia db:rollback    # ロールバック
salvia db:rollback -s 3  # 3 ステップロールバック
salvia db:setup       # 作成 + マイグレーション
```

### アセット

```bash
# Tailwind CSS
salvia css:build      # CSS ビルド
salvia css:watch      # CSS ウォッチ

# SSR Islands
salvia ssr:build      # SSR バンドルビルド
salvia ssr:watch      # SSR ウォッチ

# アセットプリコンパイル（本番用）
salvia assets:precompile
```

### ユーティリティ

```bash
salvia routes         # ルート一覧表示
salvia version        # バージョン表示
```

---

## ルーティング

### 基本ルート

```ruby
# config/routes.rb
Salvia::Router.draw do
  # ルートルート
  root to: "home#index"

  # HTTP メソッド別ルート
  get "/about", to: "pages#about"
  get "/posts/:id", to: "posts#show"
  post "/posts", to: "posts#create"
  put "/posts/:id", to: "posts#update"
  patch "/posts/:id", to: "posts#update"
  delete "/posts/:id", to: "posts#destroy"
end
```

### RESTful リソース

```ruby
resources :posts
# 生成されるルート:
#   GET    /posts          → posts#index
#   GET    /posts/new      → posts#new
#   POST   /posts          → posts#create
#   GET    /posts/:id      → posts#show
#   GET    /posts/:id/edit → posts#edit
#   PATCH  /posts/:id      → posts#update
#   DELETE /posts/:id      → posts#destroy

# アクション限定
resources :posts, only: [:index, :show]
resources :posts, except: [:destroy]
```

### ネストリソース

```ruby
resources :posts do
  resources :comments
end
# /posts/:post_id/comments/:id
```

### 名前付きルート

```ruby
# ルート定義
get "/about", to: "pages#about", as: "about"

# コントローラー/ビューで使用
posts_path          # => "/posts"
post_path(1)        # => "/posts/1"
new_post_path       # => "/posts/new"
edit_post_path(1)   # => "/posts/1/edit"
root_path           # => "/"
about_path          # => "/about"
```

### ルーティング DSL API

| メソッド | 説明 |
|---------|------|
| `root to: "controller#action"` | ルートルート |
| `get path, to: "controller#action"` | GET リクエスト |
| `post path, to: "controller#action"` | POST リクエスト |
| `put path, to: "controller#action"` | PUT リクエスト |
| `patch path, to: "controller#action"` | PATCH リクエスト |
| `delete path, to: "controller#action"` | DELETE リクエスト |
| `resources :name` | RESTful リソース |
| `resources :name, only: [...]` | 限定アクション |
| `resources :name, except: [...]` | 除外アクション |

---

## コントローラー

### 基本構造

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.all
    # render "posts/index" は自動で呼ばれる
  end

  def show
    @post = Post.find(params["id"])
  end

  def create
    @post = Post.create!(post_params)
    flash[:notice] = "投稿を作成しました"
    redirect_to post_path(@post.id)
  end

  def destroy
    Post.find(params["id"]).destroy
    redirect_to posts_path
  end

  private

  def post_params
    params.slice("title", "body")
  end
end
```

### 利用可能なメソッド

| メソッド | 説明 |
|---------|------|
| `params` | リクエストパラメータ（URL + クエリ + ボディ統合） |
| `session` | セッションハッシュ |
| `flash` | フラッシュメッセージ |
| `request` | Rack::Request オブジェクト |
| `response` | Rack::Response オブジェクト |
| `logger` | Logger インスタンス |

### render メソッド

```ruby
# テンプレート（レイアウト付き）
render "posts/show"

# レイアウトなし
render "posts/show", layout: false

# カスタムレイアウト
render "posts/show", layout: "admin"

# ステータスコード指定
render "posts/show", status: 201

# ローカル変数
render "posts/show", locals: { featured: true }

# パーシャル（レイアウトなし、_プレフィックス自動）
render partial: "posts/post"

# プレーンテキスト
render plain: "Hello, World!"

# JSON レスポンス
render json: { data: @posts, count: @posts.size }
```

### redirect_to メソッド

```ruby
# URL へリダイレクト
redirect_to "/posts"

# 名前付きルートへリダイレクト
redirect_to posts_path
redirect_to post_path(@post.id)

# ステータスコード指定
redirect_to posts_path, status: 301

# POST/PATCH/DELETE からのリダイレクトは自動で 303 (See Other)
# GET/HEAD からのリダイレクトは自動で 302 (Found)
```

### セッション

```ruby
# 値の設定
session[:user_id] = user.id

# 値の取得
current_user_id = session[:user_id]

# 値の削除
session.delete(:user_id)
```

### フラッシュメッセージ

```ruby
def create
  @post = Post.create!(params["post"])
  flash[:notice] = "投稿を作成しました"
  redirect_to posts_path
end

def update
  unless valid?
    flash.now[:alert] = "エラーがあります"  # 現在のリクエストのみ
    render "posts/edit"
  end
end
```

---

## ビュー

### レイアウト

```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <title>My App</title>
  <link rel="stylesheet" href="<%= asset_path("stylesheets/tailwind.css") %>">
  <%= csrf_meta_tags %>
</head>
<body>
  <% if flash[:notice] %>
    <div class="bg-green-100 p-4"><%= flash[:notice] %></div>
  <% end %>
  <% if flash[:alert] %>
    <div class="bg-red-100 p-4"><%= flash[:alert] %></div>
  <% end %>

  <%= yield %>

  <script src="<%= asset_path("javascripts/app.js") %>"></script>
</body>
</html>
```

### テンプレート

```erb
<!-- app/views/posts/index.html.erb -->
<h1>投稿一覧</h1>

<ul>
  <% @posts.each do |post| %>
    <li>
      <%= link_to post.title, post_path(post.id) %>
    </li>
  <% end %>
</ul>

<%= link_to "新規作成", new_post_path, class: "btn" %>
```

### パーシャル

```erb
<!-- app/views/posts/_post.html.erb -->
<article class="post">
  <h2><%= post.title %></h2>
  <p><%= post.body %></p>
</article>

<!-- 使用方法 -->
<%= render partial: "posts/post", locals: { post: @post } %>
```

### View Component

```ruby
# app/components/user_card_component.rb
class UserCardComponent < Salvia::Component
  def initialize(user:, show_avatar: true)
    @user = user
    @show_avatar = show_avatar
  end
end
```

```erb
<!-- app/components/user_card_component.html.erb -->
<div class="user-card">
  <% if @show_avatar %>
    <img src="<%= @user.avatar_url %>" alt="<%= @user.name %>">
  <% end %>
  <h3><%= @user.name %></h3>
</div>
```

```erb
<!-- ビューでの使用 -->
<%= component "user_card", user: @user %>
```

---

## ヘルパー

### タグヘルパー

```ruby
tag(:div, class: "container") { "コンテンツ" }
# => <div class="container">コンテンツ</div>

tag(:input, type: "text", name: "title")
# => <input type="text" name="title">

# data 属性
tag(:div, data: { id: 1, action: "click" }) { "クリック" }
# => <div data-id="1" data-action="click">クリック</div>
```

### リンクヘルパー

```ruby
link_to "ホーム", "/"
# => <a href="/">ホーム</a>

link_to "投稿", post_path(1), class: "btn"
# => <a href="/posts/1" class="btn">投稿</a>
```

### フォームヘルパー

```ruby
# フォーム開始
form_tag("/posts", method: :post)
# => <form action="/posts" method="post">
#    <input type="hidden" name="authenticity_token" value="...">

# PUT/PATCH/DELETE の場合
form_tag(post_path(1), method: :patch)
# => <form action="/posts/1" method="post">
#    <input type="hidden" name="_method" value="patch">

# フォーム終了
form_close
# => </form>
```

### CSRF ヘルパー

```ruby
csrf_token          # => "abc123..."
csrf_meta_tags      # => <meta name="csrf-token" content="abc123...">
csrf_field          # => <input type="hidden" name="authenticity_token" value="...">
```

### アセットヘルパー

```ruby
asset_path("stylesheets/tailwind.css")
# 開発: "/assets/stylesheets/tailwind.css"
# 本番: "/assets/stylesheets/tailwind-abc123.css" (ハッシュ付き)
```

---

## SSR Islands

### Island コンポーネントの作成

```jsx
// app/islands/Counter.js
import { h } from "https://esm.sh/preact@10.19.3";
import { useState } from "https://esm.sh/preact@10.19.3/hooks";

export function Counter({ initialCount = 0 }) {
  const [count, setCount] = useState(initialCount);

  return (
    <div className="p-4 border rounded">
      <p className="text-2xl font-bold">{count}</p>
      <button
        onClick={() => setCount(count + 1)}
        className="px-4 py-2 bg-blue-500 text-white rounded"
      >
        +1
      </button>
    </div>
  );
}
```

### ERB での使用

```erb
<h1>カウンターデモ</h1>

<%# SSR + クライアントハイドレーション %>
<%= island "Counter", { initialCount: 10 } %>
```

### island ヘルパーオプション

```ruby
island "Counter", { count: 5 }
island "Counter", { count: 5 }, ssr: false      # SSR 無効
island "Counter", { count: 5 }, hydrate: false  # ハイドレーション無効
island "Counter", { count: 5 }, tag: :section   # カスタムタグ
```

### SSR ビルド

```bash
salvia ssr:build   # ビルド
salvia ssr:watch   # ウォッチモード
salvia dev         # サーバー + SSR ウォッチ
```

### 動作フロー

```
1. SSR: QuickJS で Preact を HTML にレンダリング（0.3ms/render）
2. HTML: ERB に埋め込み
3. Hydrate: クライアント側で hydrate()
4. Interactive: クリックや入力が動作
```

---

## データベース

### 設定

```yaml
# config/database.yml
development:
  adapter: sqlite3
  database: db/development.sqlite3

production:
  adapter: postgresql
  url: <%= ENV['DATABASE_URL'] %>
```

### マイグレーション

```bash
salvia g migration create_posts title:string body:text
salvia db:migrate
salvia db:rollback
```

### モデル

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  validates :title, presence: true
  has_many :comments
end
```

---

## テスト

### セットアップ

```ruby
# test/test_helper.rb
require "salvia_rb/test"
require_relative "../config/environment"

class SalviaTest < Minitest::Test
  include Rack::Test::Methods
  include Salvia::Test::ControllerHelper

  def app
    Salvia::Application.new
  end
end
```

### コントローラーテスト

```ruby
class PostsControllerTest < SalviaTest
  def test_index
    get "/posts"
    assert last_response.ok?
  end

  def test_create
    post "/posts", { title: "New Post" }
    assert last_response.redirect?
  end
end
```

---

## デプロイ

### 環境変数（本番）

```bash
export RACK_ENV=production
export SESSION_SECRET=your-secure-secret-min-64-chars
export DATABASE_URL=postgresql://user:pass@host:5432/dbname
```

### Docker

```bash
docker compose up              # 開発
docker build -t myapp .        # 本番ビルド
docker run -p 9292:9292 myapp  # 実行
```

### セキュリティチェックリスト

- [ ] すべてのフォームに CSRF トークン
- [ ] ユーザー入力をエスケープ
- [ ] パラメータ化された SQL クエリ
- [ ] セッション Cookie のセキュア設定
- [ ] 本番環境で HTTPS

---

*Last updated: 2025-12-10 (v0.1.0)*
