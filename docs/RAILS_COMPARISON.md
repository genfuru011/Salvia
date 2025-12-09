# Salvia vs Rails 構文比較ガイド

Rails 開発者向けの Salvia クイックリファレンス。約 80% の構文が同じです！

---

## 📊 概要比較

| 項目 | Rails | Salvia |
|------|-------|--------|
| **サイズ** | フルスタック（大） | マイクロ（軽量） |
| **フロントエンド** | Hotwire / Turbo | Preact Islands |
| **JS ビルド** | esbuild / Node | Deno |
| **SSR** | 複雑 | QuickJS で簡単 |
| **ORM** | ActiveRecord | ActiveRecord |
| **テンプレート** | ERB | ERB |
| **設定量** | 多い | 最小限 |
| **起動速度** | 遅め | 高速 |

---

## 🛤️ ルーティング

### Rails

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "home#index"
  
  resources :posts do
    member do
      patch :publish
    end
    collection do
      get :drafts
    end
  end
  
  get "/about", to: "pages#about", as: :about
  namespace :admin do
    resources :users
  end
end
```

### Salvia

```ruby
# config/routes.rb
Salvia::Router.define do
  root "home#index"
  
  # resources は手動で定義
  get "/posts", "posts#index"
  get "/posts/drafts", "posts#drafts"
  get "/posts/:id", "posts#show"
  post "/posts", "posts#create"
  patch "/posts/:id", "posts#update"
  delete "/posts/:id", "posts#destroy"
  patch "/posts/:id/publish", "posts#publish"
  
  get "/about", "pages#about", as: :about
  
  # namespace は手動
  get "/admin/users", "admin/users#index"
end
```

**違い：** `resources` ヘルパーなし。シンプルに手動定義。

---

## 🎮 コントローラー

### 基本構造

```ruby
# Rails
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :update, :destroy]
  
  def index
    @posts = Post.all
  end

  def show
  end

  def create
    @post = Post.create!(post_params)
    redirect_to @post, notice: "作成しました"
  end

  private
  
  def set_post
    @post = Post.find(params[:id])
  end
  
  def post_params
    params.require(:post).permit(:title, :body)
  end
end

# Salvia
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end

  def show
    @post = Post.find(params[:id])
  end

  def create
    @post = Post.create!(
      title: params[:title],
      body: params[:body]
    )
    flash[:notice] = "作成しました"
    redirect_to post_path(id: @post.id)
  end
end
```

**違い：**
- `before_action` なし（今後対応予定）
- Strong Parameters なし（シンプルに直接取得）
- `redirect_to @post` → `redirect_to post_path(id: @post.id)`

### レンダリング

```ruby
# Rails
render :show
render action: :new
render json: @post
render json: @post, status: :created
render partial: "post", locals: { post: @post }
render partial: "post", collection: @posts
render template: "shared/error", status: 404
render plain: "OK"
render html: "<p>Hello</p>".html_safe
redirect_to posts_path
redirect_to @post, notice: "成功"

# Salvia
render "posts/show"
render "posts/new"
render json: @post
render json: @post, status: 201
render partial: "post", locals: { post: @post }
render partial: "post", collection: @posts
render template: "shared/error", status: 404
render plain: "OK"
render html: "<p>Hello</p>"
redirect_to posts_path
redirect_to post_path(id: @post.id)  # notice は flash で別途
```

### パラメータ

```ruby
# Rails
params[:id]                         # URL パラメータ
params[:post][:title]               # ネストしたパラメータ
params.require(:post).permit(:title) # Strong Parameters

# Salvia
params[:id]                         # URL パラメータ
params[:title]                      # JSON body も自動パース
# Strong Parameters なし - 直接アクセス
```

### セッション & フラッシュ

```ruby
# Rails
session[:user_id] = user.id
session.delete(:user_id)
flash[:notice] = "成功"
flash[:alert] = "エラー"
flash.now[:notice] = "一時的"

# Salvia
session[:user_id] = user.id
session.delete(:user_id)
flash[:notice] = "成功"
flash[:error] = "エラー"
# flash.now は未対応
```

### CSRF

```ruby
# Rails - コントローラー
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# Salvia - 自動（ミドルウェアで処理）
class ApplicationController < Salvia::Controller
  # 自動で保護される
end
```

```ruby
# CSRF トークン取得
# Rails
form_authenticity_token

# Salvia
csrf_token
```

---

## 📄 ビュー / テンプレート

### リンク

```erb
<%# Rails %>
<%= link_to "投稿一覧", posts_path %>
<%= link_to "詳細", @post %>
<%= link_to "詳細", post_path(@post) %>
<%= link_to "削除", @post, method: :delete, data: { confirm: "本当に？" } %>

<%# Salvia %>
<a href="<%= posts_path %>">投稿一覧</a>
<a href="<%= post_path(id: @post.id) %>">詳細</a>
<%# method: :delete は JavaScript で実装 %>
```

### フォーム

```erb
<%# Rails %>
<%= form_with model: @post do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body %>
  <%= f.submit "保存" %>
<% end %>

<%= form_with url: search_path, method: :get do |f| %>
  <%= f.text_field :q %>
<% end %>

<%# Salvia %>
<form action="<%= posts_path %>" method="post">
  <%= csrf_input_tag %>
  <input type="text" name="title" value="<%= @post&.title %>">
  <textarea name="body"><%= @post&.body %></textarea>
  <button type="submit">保存</button>
</form>

<form action="<%= search_path %>" method="get">
  <input type="text" name="q">
</form>
```

### パーシャル

```erb
<%# Rails %>
<%= render "post", post: @post %>
<%= render partial: "post", locals: { post: @post } %>
<%= render @posts %>
<%= render partial: "post", collection: @posts %>
<%= render partial: "post", collection: @posts, spacer_template: "spacer" %>

<%# Salvia %>
<%= render partial: "post", locals: { post: @post } %>
<%= render partial: "post", collection: @posts %>
<%# spacer_template は未対応 %>
```

### レイアウト

```erb
<%# Rails - app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
<head>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "application" %>
  <%= javascript_include_tag "application", defer: true %>
</head>
<body>
  <%= yield %>
</body>
</html>

<%# Salvia - app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
<head>
  <%= csrf_meta_tag %>
  <link rel="stylesheet" href="/assets/stylesheets/tailwind.css">
</head>
<body>
  <%= yield %>
  <%= islands_hydration_script %>
</body>
</html>
```

### CSRF タグ

```erb
<%# Rails %>
<%= csrf_meta_tags %>
<%# 出力: <meta name="csrf-param" ...><meta name="csrf-token" ...> %>

<%= form_with ... %>  <%# 自動で hidden field 挿入 %>

<%# Salvia %>
<%= csrf_meta_tag %>
<%# 出力: <meta name="csrf-token" ...> %>

<form ...>
  <%= csrf_input_tag %>  <%# 手動で追加 %>
</form>
```

---

## 🏝️ フロントエンド

### Rails (Hotwire / Turbo)

```erb
<%# Turbo Frame %>
<%= turbo_frame_tag "posts" do %>
  <% @posts.each do |post| %>
    <%= render post %>
  <% end %>
<% end %>

<%# Turbo Stream %>
<%= turbo_stream.append "posts", partial: "post", locals: { post: @post } %>

<%# Stimulus Controller %>
<div data-controller="counter">
  <span data-counter-target="count">0</span>
  <button data-action="click->counter#increment">+1</button>
</div>
```

```javascript
// Stimulus Controller
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count"]
  
  increment() {
    this.countTarget.textContent = parseInt(this.countTarget.textContent) + 1
  }
}
```

### Salvia (Preact Islands)

```erb
<%# ERB で Island を呼び出し %>
<%= island "Counter", count: 0 %>

<%# Props を渡す %>
<%= island "PostList", posts: @posts, csrf_token: @csrf_token %>
```

```jsx
// app/islands/Counter.jsx
import { useState } from 'preact/hooks';

export default function Counter({ count: initialCount }) {
  const [count, setCount] = useState(initialCount);
  
  return (
    <div>
      <span>{count}</span>
      <button onClick={() => setCount(c => c + 1)}>+1</button>
    </div>
  );
}
```

```jsx
// app/islands/PostList.jsx - API 連携
import { useState } from 'preact/hooks';

export default function PostList({ posts: initialPosts, csrfToken }) {
  const [posts, setPosts] = useState(initialPosts);

  const deletePost = async (id) => {
    await fetch(`/posts/${id}`, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': csrfToken }
    });
    setPosts(posts.filter(p => p.id !== id));
  };

  return (
    <ul>
      {posts.map(post => (
        <li key={post.id}>
          {post.title}
          <button onClick={() => deletePost(post.id)}>削除</button>
        </li>
      ))}
    </ul>
  );
}
```

**違い：**
- Rails: HTML 中心、サーバーレンダリング
- Salvia: React 風、コンポーネント志向、SSR + ハイドレーション

---

## 🗄️ モデル

```ruby
# Rails（同じ！）
class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  
  validates :title, presence: true
  validates :body, length: { minimum: 10 }
  
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  before_save :normalize_title
  
  private
  
  def normalize_title
    self.title = title.strip.titleize
  end
end

# Salvia（同じ！）
class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  
  validates :title, presence: true
  validates :body, length: { minimum: 10 }
  
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  before_save :normalize_title
  
  private
  
  def normalize_title
    self.title = title.strip.titleize
  end
end
```

**違い：** なし！ActiveRecord をそのまま使用。

---

## 🔄 マイグレーション

```ruby
# Rails（同じ！）
class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.boolean :published, default: false
      t.references :user, foreign_key: true
      t.timestamps
    end
    
    add_index :posts, :published
  end
end

# Salvia（同じ！）
class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.boolean :published, default: false
      t.references :user, foreign_key: true
      t.timestamps
    end
    
    add_index :posts, :published
  end
end
```

**違い：** なし！

---

## 🔧 CLI コマンド

| 機能 | Rails | Salvia |
|------|-------|--------|
| 新規作成 | `rails new app` | `salvia new app` |
| サーバー | `rails server` | `salvia server` |
| コンソール | `rails console` | `salvia console` |
| モデル生成 | `rails g model Post` | `salvia g model Post` |
| コントローラー生成 | `rails g controller Posts` | `salvia g controller Posts` |
| マイグレーション | `rails db:migrate` | `salvia db:migrate` |
| ロールバック | `rails db:rollback` | `salvia db:rollback` |
| シード | `rails db:seed` | `salvia db:seed` |
| ルート確認 | `rails routes` | `salvia routes` |

---

## ⚙️ 設定ファイル

### Rails

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.load_defaults 7.0
    config.time_zone = "Tokyo"
  end
end

# config/routes.rb
Rails.application.routes.draw do
  # ...
end

# config/database.yml
development:
  adapter: sqlite3
  database: db/development.sqlite3
```

### Salvia

```ruby
# config/environment.rb
require "bundler/setup"
require "salvia_rb"

Salvia.root = File.expand_path("..", __dir__)
Salvia.env = ENV.fetch("RACK_ENV", "development")

# SSR 設定
Salvia::SSR.configure(
  bundle_path: File.join(Salvia.root, "vendor/server/ssr_bundle.js"),
  development: Salvia.env == "development"
)

require_relative "routes"

# config/routes.rb
Salvia::Router.define do
  # ...
end

# config/database.yml（同じ！）
development:
  adapter: sqlite3
  database: db/development.sqlite3
```

---

## 📦 Gemfile

### Rails

```ruby
source "https://rubygems.org"

gem "rails", "~> 7.0"
gem "sqlite3"
gem "puma"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "bootsnap", require: false

group :development do
  gem "web-console"
  gem "debug"
end
```

### Salvia

```ruby
source "https://rubygems.org"

gem "salvia_rb"
gem "sqlite3"
gem "puma"
gem "quickjs"  # SSR 用

group :development do
  gem "debug"
end
```

**違い：** Salvia は依存が少ない！

---

## 🚀 移行チェックリスト

Rails → Salvia への移行時に変更が必要な箇所：

### ✅ そのまま使える
- [x] モデル（ActiveRecord）
- [x] マイグレーション
- [x] バリデーション
- [x] アソシエーション
- [x] スコープ
- [x] コールバック
- [x] ERB 基本構文
- [x] セッション
- [x] フラッシュ

### 🔄 書き換えが必要
- [ ] `resources` → 手動ルート定義
- [ ] `link_to` → `<a href="">` タグ
- [ ] `form_with` → `<form>` タグ + `csrf_input_tag`
- [ ] `before_action` → 各アクション内で実行
- [ ] Strong Parameters → 直接 `params[:key]`
- [ ] `redirect_to @post` → `redirect_to post_path(id: @post.id)`
- [ ] Hotwire/Turbo → Preact Islands

### ❌ 未対応（将来対応予定）
- [ ] Action Cable (WebSocket)
- [ ] Active Job (バックグラウンドジョブ)
- [ ] Action Mailer (メール)
- [ ] Active Storage (ファイルアップロード)

---

## 💡 なぜ Salvia？

| 観点 | Rails | Salvia |
|------|-------|--------|
| **学習コスト** | 高い | 低い（Rails 経験あれば即戦力） |
| **起動速度** | 遅い | 高速 |
| **メモリ使用量** | 多い | 少ない |
| **フロントエンド** | HTML 中心 | React 風コンポーネント |
| **SSR** | 複雑 | 簡単（QuickJS 内蔵） |
| **小規模プロジェクト** | オーバーキル | 最適 |
| **大規模プロジェクト** | 最適 | 成長中 |

**結論：** Rails の良さを活かしつつ、モダンなフロントエンド開発体験を提供！🌿
