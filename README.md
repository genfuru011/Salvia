<p align="center">
  <img src="https://img.shields.io/badge/Ruby-3.1+-CC342D?style=flat-square&logo=ruby" alt="Ruby">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/Version-0.1.0-6A5ACD?style=flat-square" alt="Version">
</p>

<h1 align="center">🌿 Salvia.rb</h1>

<p align="center">
  <strong>"Wisdom for Rubyists."</strong><br>
  A tiny Ruby MVC framework for wise and clear web apps.
</p>

<p align="center">
  HTMX × Tailwind × ActiveRecord を前提にした<br>
  小さくて理解しやすい Ruby MVC フレームワーク
</p>

---

## ✨ Features

- **🖥️ サーバーレンダリング (HTML) ファースト** - JSON API ではなく HTML を返す
- **⚡ Smart Rendering** - HTMX リクエストを自動検出してレイアウトを除外
- **🛤️ Rails-like DSL** - 馴染みのある `resources`, `root to:` などのルーティング
- **🗃️ ActiveRecord 統合** - Rails と同じ感覚でモデルを扱える
- **📦 Node.js 不要** - `tailwindcss-ruby` で CSS をビルド

## 🎯 Philosophy

> **"Write less, see more."**

| Rails | Salvia |
|-------|--------|
| フルスタック・オールインワン | 必要最小限のコア機能 |
| 設定より規約 | 明示的で理解しやすい |
| JSON API + SPA | HTML + HTMX |
| 大規模向け | 小〜中規模向け |

## 🚀 Quick Start

```bash
# Install the gem
gem install salvia_rb

# Create a new app
salvia new myapp
cd myapp

# Setup
bundle install
salvia db:setup
salvia css:build

# Start the server
salvia server
```

ブラウザで http://localhost:9292 を開いてください 🌿

## 📖 Documentation

| ドキュメント | 説明 |
|-------------|------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 内部構造と設計思想 |
| [docs/ROADMAP.md](docs/ROADMAP.md) | 開発ロードマップ |
| [docs/SECURITY_ASSESSMENT.md](docs/SECURITY_ASSESSMENT.md) | セキュリティ脆弱性リスク評価 |
| [docs/SECURITY_GUIDE.md](docs/SECURITY_GUIDE.md) | セキュリティガイド |
| [docs/SECURITY_CHECKLIST.md](docs/SECURITY_CHECKLIST.md) | セキュリティチェックリスト |
| [CHANGELOG.md](CHANGELOG.md) | 変更履歴 |
| [docs/Idea.md](docs/Idea.md) | 元のアイデアメモ |

## 📁 Project Structure

```
Salvia/
├── salvia_rb/          # Gem ソースコード
│   ├── lib/
│   │   └── salvia_rb/
│   │       ├── application.rb   # Rack アプリ
│   │       ├── router.rb        # ルーティング
│   │       ├── controller.rb    # コントローラー
│   │       ├── database.rb      # ActiveRecord 統合
│   │       └── cli.rb           # CLI コマンド
│   └── exe/
│       └── salvia              # CLI エントリーポイント
├── docs/               # ドキュメント
│   ├── ARCHITECTURE.md
│   ├── ROADMAP.md
│   └── ...
├── CHANGELOG.md        # 変更履歴
└── README.md           # このファイル
```

## 🎨 Example: Todo App with HTMX

### Routes

```ruby
# config/routes.rb
Salvia::Router.draw do
  root to: "todos#index"
  resources :todos, only: [:index, :create, :destroy]
end
```

### Controller

```ruby
# app/controllers/todos_controller.rb
class TodosController < ApplicationController
  def index
    @todos = Todo.order(created_at: :desc)
    render "todos/index"
  end

  def create
    @todo = Todo.create!(title: params["title"])
    render "todos/_todo", locals: { todo: @todo }
  end

  def destroy
    Todo.find(params["id"]).destroy
    head :ok
  end
end
```

### View with HTMX

```erb
<!-- app/views/todos/index.html.erb -->
<div class="max-w-md mx-auto mt-8">
  <h1 class="text-2xl font-bold text-salvia-700 mb-4">📝 Todos</h1>

  <form hx-post="/todos" hx-target="#todo-list" hx-swap="afterbegin"
        class="flex gap-2 mb-4">
    <input name="title" placeholder="New todo..."
           class="flex-1 border rounded px-3 py-2">
    <button class="bg-salvia-500 text-white px-4 py-2 rounded">
      Add
    </button>
  </form>

  <ul id="todo-list" class="space-y-2">
    <% @todos.each do |todo| %>
      <%= render "todos/_todo", locals: { todo: todo } %>
    <% end %>
  </ul>
</div>
```

```erb
<!-- app/views/todos/_todo.html.erb -->
<li class="flex items-center gap-2 p-2 bg-white rounded shadow">
  <span class="flex-1"><%= todo.title %></span>
  <button hx-delete="/todos/<%= todo.id %>"
          hx-target="closest li"
          hx-swap="outerHTML"
          class="text-red-500 hover:text-red-700">
    ✕
  </button>
</li>
```

## 🛠️ CLI Commands

```bash
salvia new APP_NAME     # Create new app
salvia server           # Start server (alias: s)
salvia console          # Start IRB (alias: c)
salvia db:create        # Create database
salvia db:migrate       # Run migrations
salvia db:rollback      # Rollback migration
salvia db:setup         # Create + migrate
salvia css:build        # Build Tailwind CSS
salvia css:watch        # Watch CSS changes
salvia routes           # List all routes
salvia version          # Show version
```

## 🔧 Requirements

- Ruby 3.1+
- Bundler 2.0+

## 📦 Dependencies

| Gem | Purpose |
|-----|---------|
| rack | HTTP interface |
| puma | Web server |
| mustermann | Route matching |
| tilt + erubi | Template rendering |
| activerecord | ORM |
| thor | CLI |
| zeitwerk | Auto-loading |
| tailwindcss-ruby | CSS (no Node.js) |

## 🗺️ Roadmap

- [x] **v0.1.0** - Foundation (Router, Controller, CLI)
- [ ] **v0.2.0** - Developer Experience (Zeitwerk, Error pages)
- [ ] **v0.3.0** - Security (CSRF, Session, Flash)
- [ ] **v0.4.0** - Production Ready (Assets, Logging)
- [ ] **v1.0.0** - Stable Release

詳細は [docs/ROADMAP.md](docs/ROADMAP.md) を参照してください。

## 🔒 Security

セキュリティは重要です。Salvia.rb を使用する前に、以下のドキュメントを確認してください:

- **[セキュリティ脆弱性リスク評価](docs/SECURITY_ASSESSMENT.md)** - 現在のバージョンの既知の脆弱性とリスク
- **[セキュリティガイド](docs/SECURITY_GUIDE.md)** - 安全なアプリケーション開発のベストプラクティス
- **[セキュリティチェックリスト](docs/SECURITY_CHECKLIST.md)** - 開発・デプロイ時のチェック項目

### ⚠️ 重要な注意事項

**現在のバージョン (v0.1.0) には、重大なセキュリティ上の懸念があります:**

- 🔴 CSRF 保護が不完全
- 🔴 XSS 対策の自動エスケープが未設定
- 🟠 セッション管理のセキュリティ設定が不十分

**本番環境での使用は推奨しません。** v0.3.0 (Security Phase) のリリースをお待ちください。

### 脆弱性の報告

セキュリティ脆弱性を発見した場合は、公開 Issue を作成せず、メンテナーに直接ご連絡ください。

## 📝 License

[MIT License](LICENSE)

## 🤝 Contributing

Bug reports and pull requests are welcome!

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Create a Pull Request

---

<p align="center">
  <em>"Simple, like a flower. Solid, like a gem."</em> 🌿
</p>

