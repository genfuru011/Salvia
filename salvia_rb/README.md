# 🌿 Salvia.rb

> **"Wisdom for Rubyists."**
>
> 小さくて理解しやすい Ruby MVC フレームワーク

HTMX × Tailwind × ActiveRecord を前提にした、シンプルで明快な Ruby Web フレームワークです。

## 特徴

- **サーバーレンダリング (HTML) ファースト** - JSON API ではなく HTML を返す
- **Smart Rendering** - HTMX リクエストを自動検出してレイアウトを除外
- **Rails ライクな DSL** - 馴染みのある `resources`, `root to:` などのルーティング
- **ActiveRecord 統合** - Rails と同じ感覚でモデルを扱える
- **Node.js 不要** - `tailwindcss-ruby` で CSS をビルド

## インストール

```ruby
gem "salvia_rb"
```

## クイックスタート

```bash
# 新しいアプリを作成
salvia new myapp
cd myapp

# セットアップ
bundle install
salvia db:setup
salvia css:build

# サーバー起動
salvia server
```

ブラウザで http://localhost:9292 を開くと、ウェルカムページが表示されます。

## ディレクトリ構造

```
myapp/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── home_controller.rb
│   ├── models/
│   │   └── application_record.rb
│   └── views/
│       ├── layouts/
│       │   └── application.html.erb
│       └── home/
│           └── index.html.erb
├── config/
│   ├── database.yml
│   ├── environment.rb
│   └── routes.rb
├── db/
│   └── migrate/
├── public/
│   └── assets/
├── config.ru
└── Gemfile
```

## ルーティング

```ruby
# config/routes.rb
Salvia::Router.draw do
  root to: "home#index"

  get "/about", to: "pages#about"

  resources :posts, only: [:index, :show, :create]
  resources :comments, only: [:create, :destroy]
end
```

## コントローラー

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.order(created_at: :desc)
    render "posts/index"
  end

  def create
    @post = Post.create!(title: params["title"], body: params["body"])

    # HTMX リクエストならパーシャルのみ返す（Smart Rendering）
    render "posts/_post", locals: { post: @post }
  end
end
```

## HTMX を使ったビュー

```erb
<!-- app/views/posts/index.html.erb -->
<div class="max-w-2xl mx-auto">
  <form hx-post="/posts" hx-target="#posts" hx-swap="afterbegin">
    <input name="title" placeholder="タイトル" class="border rounded px-2 py-1">
    <button class="bg-blue-500 text-white px-4 py-1 rounded">追加</button>
  </form>

  <div id="posts">
    <% @posts.each do |post| %>
      <%= render "posts/_post", locals: { post: post } %>
    <% end %>
  </div>
</div>
```

## CLI コマンド

| コマンド | 説明 |
|---------|------|
| `salvia new APP_NAME` | 新しいアプリケーションを作成 |
| `salvia server` / `salvia s` | 開発サーバーを起動 |
| `salvia console` / `salvia c` | IRB コンソールを起動 |
| `salvia db:create` | データベースを作成 |
| `salvia db:migrate` | マイグレーションを実行 |
| `salvia db:rollback` | 直前のマイグレーションをロールバック |
| `salvia db:setup` | データベースの作成とマイグレーション |
| `salvia css:build` | Tailwind CSS をビルド |
| `salvia css:watch` | CSS の変更を監視してリビルド |
| `salvia routes` | ルート一覧を表示 |

## Smart Rendering

Salvia は HTMX リクエスト（`HX-Request` ヘッダー）を自動検出し、レイアウトをスキップします：

```ruby
def create
  @item = Item.create!(params)

  # 通常リクエスト: レイアウト付きでレンダリング
  # HTMX リクエスト: パーシャルのみ（レイアウトなし）
  render "items/_item", locals: { item: @item }
end
```

## 動作環境

- Ruby 3.1 以上
- SQLite3（デフォルト）または PostgreSQL/MySQL

## ライセンス

MIT License

## コントリビュート

バグ報告やプルリクエストを歓迎します！

---

*"Simple, like a flower. Solid, like a gem."* 🌿
