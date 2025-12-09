# Salvia 構文ガイド

Salvia フレームワークの基本的な構文とパターンをまとめたガイドです。

## 📁 プロジェクト構造

```
my_app/
├── app/
│   ├── controllers/      # コントローラー
│   ├── models/           # ActiveRecord モデル
│   ├── views/            # ERB テンプレート
│   │   └── layouts/      # レイアウト
│   ├── islands/          # Preact Islands (JSX)
│   └── assets/
│       └── stylesheets/  # CSS/Tailwind
├── config/
│   ├── environment.rb    # アプリ設定
│   ├── routes.rb         # ルーティング
│   └── database.yml      # DB 設定
├── db/
│   ├── migrate/          # マイグレーション
│   └── seeds.rb          # シードデータ
├── public/               # 静的ファイル
├── vendor/               # ビルド成果物
├── config.ru             # Rack 設定
├── Gemfile               # Ruby 依存関係
└── deno.json             # Deno/Islands 設定
```

---

## 🛤️ ルーティング (config/routes.rb)

```ruby
Salvia::Router.define do
  # 基本ルート
  root "home#index"                    # GET / → HomeController#index

  # RESTful ルート
  get "/posts", "posts#index"          # GET /posts
  get "/posts/:id", "posts#show"       # GET /posts/123
  post "/posts", "posts#create"        # POST /posts
  patch "/posts/:id", "posts#update"   # PATCH /posts/123
  delete "/posts/:id", "posts#destroy" # DELETE /posts/123

  # カスタムアクション
  patch "/tasks/:id/toggle", "tasks#toggle"

  # 名前付きルート (ヘルパー生成)
  get "/about", "pages#about", as: :about
  # → about_path => "/about"
end
```

---

## 🎮 コントローラー (app/controllers/)

```ruby
class PostsController < ApplicationController
  # インデックス
  def index
    @posts = Post.all.order(created_at: :desc)
  end

  # 詳細
  def show
    @post = Post.find(params[:id])
  end

  # 作成 (JSON API)
  def create
    post = Post.create!(
      title: params[:title],    # JSON body も自動パース
      body: params[:body]
    )
    render json: post           # JSON レスポンス
  end

  # 更新
  def update
    post = Post.find(params[:id])
    post.update!(title: params[:title])
    render json: post
  end

  # 削除
  def destroy
    Post.find(params[:id]).destroy!
    render json: { success: true }
  end
end
```

### レンダリングオプション

```ruby
# テンプレートを指定
render "posts/show"

# 別のテンプレート
render template: "shared/error"

# JSON レスポンス
render json: { data: @posts }

# プレーンテキスト
render plain: "Hello"

# ステータスコード
render json: { error: "Not found" }, status: 404

# レイアウトなし
render layout: false

# 別のレイアウト
render layout: "admin"

# リダイレクト
redirect_to "/posts"
redirect_to posts_path
```

### 利用可能なメソッド

```ruby
# パラメータ
params[:id]          # URL パラメータ & JSON body
params[:title]

# リクエスト
request.path         # "/posts/123"
request.method       # "GET", "POST", etc.
request.xhr?         # Ajax リクエスト?

# セッション
session[:user_id]    # セッションデータ
session[:user_id] = 123

# フラッシュメッセージ
flash[:notice] = "保存しました"
flash[:error] = "エラーが発生しました"

# CSRF
csrf_token           # トークン取得
csrf_meta_tag        # <meta name="csrf-token" ...>
```

---

## 📄 ビュー / テンプレート (app/views/)

### ERB 構文

```erb
<%# コメント %>

<% Ruby コード %>
<%= 出力する Ruby 式 %>

<%# 条件分岐 %>
<% if @posts.any? %>
  <p>投稿があります</p>
<% else %>
  <p>投稿がありません</p>
<% end %>

<%# ループ %>
<% @posts.each do |post| %>
  <div><%= post.title %></div>
<% end %>
```

### ヘルパー

```erb
<%# ルートヘルパー %>
<a href="<%= posts_path %>">投稿一覧</a>
<a href="<%= post_path(id: @post.id) %>">詳細</a>

<%# CSRF メタタグ (レイアウトに追加) %>
<%= csrf_meta_tag %>

<%# Island コンポーネント %>
<%= island "Counter", count: 5 %>
<%= island "TaskList", tasks: @tasks, csrf_token: @csrf_token %>

<%# パーシャル %>
<%= render partial: "posts/post", locals: { post: @post } %>

<%# パーシャル (コレクション) %>
<%= render partial: "posts/post", collection: @posts %>
```

### レイアウト (app/views/layouts/application.html.erb)

```erb
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>My App</title>
  <%= csrf_meta_tag %>
  <link rel="stylesheet" href="/assets/stylesheets/tailwind.css">
</head>
<body>
  <%= yield %>
  
  <%= islands_hydration_script %>
</body>
</html>
```

---

## 🏝️ Islands (app/islands/)

Preact ベースのインタラクティブコンポーネント。

### 基本構造 (Counter.jsx)

```jsx
import { useState } from 'preact/hooks';

export default function Counter({ count: initialCount = 0 }) {
  const [count, setCount] = useState(initialCount);

  return (
    <div class="p-4 bg-white rounded shadow">
      <p class="text-xl">Count: {count}</p>
      <button
        onClick={() => setCount(count + 1)}
        class="px-4 py-2 bg-blue-500 text-white rounded"
      >
        +1
      </button>
    </div>
  );
}
```

### API 連携 (TaskList.jsx)

```jsx
import { useState } from 'preact/hooks';

export default function TaskList({ tasks: initialTasks = [], csrfToken }) {
  const [tasks, setTasks] = useState(initialTasks);
  const [newTask, setNewTask] = useState('');

  const addTask = async (e) => {
    e.preventDefault();
    if (!newTask.trim()) return;

    const res = await fetch('/tasks', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken  // CSRF トークン必須
      },
      body: JSON.stringify({ title: newTask })
    });
    const task = await res.json();
    setTasks([...tasks, task]);
    setNewTask('');
  };

  const deleteTask = async (id) => {
    await fetch(`/tasks/${id}`, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': csrfToken }
    });
    setTasks(tasks.filter(t => t.id !== id));
  };

  return (
    <div>
      <form onSubmit={addTask}>
        <input
          type="text"
          value={newTask}
          onInput={(e) => setNewTask(e.target.value)}
          placeholder="New task..."
        />
        <button type="submit">Add</button>
      </form>

      <ul>
        {tasks.map(task => (
          <li key={task.id}>
            {task.title}
            <button onClick={() => deleteTask(task.id)}>×</button>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### クライアントオンリー Island

SSR をスキップしたい場合（ブラウザ API 依存など）：

```jsx
"client only";  // ファイル先頭に記述

import { useState, useEffect } from 'preact/hooks';

export default function BrowserOnly() {
  const [width, setWidth] = useState(0);

  useEffect(() => {
    setWidth(window.innerWidth);  // window はブラウザのみ
  }, []);

  return <p>Window width: {width}px</p>;
}
```

### ERB から Island を呼び出す

```erb
<%# 基本 %>
<%= island "Counter", count: 10 %>

<%# 複数の props %>
<%= island "TaskList", tasks: @tasks, csrf_token: @csrf_token %>

<%# SSR 無効化 %>
<%= island "Chart", data: @data, ssr: false %>

<%# ハイドレーション無効 (静的 HTML のみ) %>
<%= island "StaticCard", title: "Hello", hydrate: false %>
```

---

## 🗄️ モデル (app/models/)

ActiveRecord ベース。

```ruby
class Post < ApplicationRecord
  # バリデーション
  validates :title, presence: true
  validates :body, length: { minimum: 10 }

  # 関連
  belongs_to :user
  has_many :comments, dependent: :destroy

  # スコープ
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
end
```

### マイグレーション (db/migrate/)

```ruby
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

---

## ⚙️ 設定ファイル

### config/environment.rb

```ruby
require "bundler/setup"
require "salvia_rb"

Salvia.root = File.expand_path("..", __dir__)
Salvia.env = ENV.fetch("RACK_ENV", "development")

# SSR 設定 (Islands 使用時)
Salvia::SSR.configure(
  bundle_path: File.join(Salvia.root, "vendor/server/ssr_bundle.js"),
  development: Salvia.env == "development"
)

require_relative "routes"
```

### config/database.yml

```yaml
development:
  adapter: sqlite3
  database: db/development.sqlite3

production:
  adapter: sqlite3
  database: db/production.sqlite3
```

### Gemfile

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

---

## 🔧 CLI コマンド

```bash
# 新規プロジェクト作成
salvia new my_app

# サーバー起動
salvia server              # http://localhost:9292
salvia server -p 3000      # ポート指定

# DB マイグレーション
salvia db:migrate
salvia db:rollback
salvia db:seed

# ジェネレーター
salvia generate model Post title:string body:text
salvia generate controller Posts index show create

# Islands ビルド
deno run -A vendor/scripts/build_ssr.ts
deno run -A vendor/scripts/build_ssr.ts --watch  # ウォッチモード
```

---

## 🔒 CSRF 保護

### レイアウトにメタタグ追加

```erb
<head>
  <%= csrf_meta_tag %>
</head>
```

### コントローラーで CSRF トークンを渡す

```ruby
def index
  @csrf_token = csrf_token
end
```

### Island から API リクエスト

```jsx
await fetch('/api/endpoint', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken  // props で受け取ったトークン
  },
  body: JSON.stringify(data)
});
```

---

## 💡 Tips

### 開発モードでの自動リロード

```bash
# 別ターミナルで Islands をウォッチ
deno run -A vendor/scripts/build_ssr.ts --watch
```

### デバッグ

```ruby
# コントローラーでデバッグ
puts params.inspect
puts @posts.to_json

# binding.break (debug gem)
def show
  @post = Post.find(params[:id])
  binding.break  # ここで停止
end
```

### 環境変数 (.env)

```bash
# .env
DATABASE_URL=sqlite3://db/production.sqlite3
SECRET_KEY_BASE=your-secret-key
```

```ruby
# 使用
ENV["DATABASE_URL"]
ENV.fetch("SECRET_KEY_BASE")
```

---

これで Salvia の基本的な構文とパターンがわかります！🌿
