<p align="center">
  <img src="https://img.shields.io/badge/Ruby-3.1+-CC342D?style=flat-square&logo=ruby" alt="Ruby">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/Version-0.5.0-6A5ACD?style=flat-square" alt="Version">
</p>

<h1 align="center">🌿 Salvia.rb</h1>

<p align="center">
  <strong>"Wisdom for Rubyists."</strong><br>
  A tiny Ruby MVC framework for wise and clear web apps.
</p>

<p align="center">
  <strong>SSR Islands Architecture</strong> × <strong>HTMX</strong> × <strong>Tailwind</strong> × <strong>ActiveRecord</strong><br>
  小さくて理解しやすい Ruby MVC フレームワーク
</p>

---

## ✨ Features

- **🖥️ サーバーレンダリング (HTML) ファースト** - JSON API ではなく HTML を返す
- **🏝️ SSR Islands Architecture** - Preact コンポーネントを QuickJS でサーバーサイドレンダリング
- **⚡ Smart Rendering** - HTMX リクエストを自動検出してレイアウトを除外
- **🛤️ Rails-like DSL** - 馴染みのある `resources`, `root to:` などのルーティング
- **🗃️ ActiveRecord 統合** - Rails と同じ感覚でモデルを扱える
- **📦 Node.js 不要** - QuickJS + Deno でビルド、本番は Node 不要

## 🎯 Philosophy

> **"Write less, see more."**

| Rails | Salvia |
|-------|--------|
| フルスタック・オールインワン | 必要最小限のコア機能 |
| Hotwire (Turbo/Stimulus) | **SSR Islands** + HTMX |
| JSON API + SPA | HTML + Islands |
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
| [docs/design/ARCHITECTURE.md](docs/design/ARCHITECTURE.md) | 内部構造と設計思想 |
| [docs/development/ROADMAP.md](docs/development/ROADMAP.md) | 開発ロードマップ |
| [docs/security/SECURITY_ASSESSMENT.md](docs/security/SECURITY_ASSESSMENT.md) | セキュリティ脆弱性リスク評価 |
| [docs/security/SECURITY_GUIDE.md](docs/security/SECURITY_GUIDE.md) | セキュリティガイド |
| [docs/security/SECURITY_CHECKLIST.md](docs/security/SECURITY_CHECKLIST.md) | セキュリティチェックリスト |
| [CHANGELOG.md](CHANGELOG.md) | 変更履歴 |
| [docs/design/Idea.md](docs/design/Idea.md) | 元のアイデアメモ |

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
│   │       ├── cli.rb           # CLI コマンド
│   │       └── ssr/             # SSR エンジン
│   │           └── adapters/
│   │               └── quickjs_hybrid.rb
│   └── exe/
│       └── salvia              # CLI エントリーポイント
├── docs/               # ドキュメント
│   ├── design/
│   ├── development/
│   └── security/
├── CHANGELOG.md        # 変更履歴
└── README.md           # このファイル
```

**生成されるアプリの構造:**

```
myapp/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── views/
│   ├── islands/             # 🏝️ Island コンポーネント (Preact/JSX)
│   │   ├── TodoItem.jsx
│   │   ├── TodoList.jsx
│   │   └── TodoStats.jsx
│   └── components/          # View Components (Ruby)
├── bin/
│   └── build_ssr.ts         # Deno ビルドスクリプト
├── vendor/server/
│   └── ssr_bundle.js        # SSR バンドル
├── public/assets/javascripts/
│   └── islands_bundle.js    # クライアントバンドル
├── config/
│   ├── database.yml
│   ├── environment.rb
│   ├── routes.rb
│   └── importmap.rb
├── db/
├── config.ru
└── Gemfile
```

## 🎨 Example: Todo App with SSR Islands

### Routes

```ruby
# config/routes.rb
Salvia::Router.draw do
  root to: "todos#index"
  resources :todos, only: [:index, :create, :destroy] do
    member do
      patch :toggle
    end
  end
end
```

### Controller

```ruby
# app/controllers/todos_controller.rb
class TodosController < ApplicationController
  def index
    @todos = Todo.order(created_at: :desc)
    @stats = {
      total: @todos.count,
      completed: @todos.where(completed: true).count
    }
    render "todos/index"
  end

  def create
    Todo.create!(title: params[:title])
    redirect_to "/"
  end

  def toggle
    todo = Todo.find(params[:id])
    todo.update!(completed: !todo.completed)
    head :ok
  end
end
```

### View with Islands

```erb
<!-- app/views/todos/index.html.erb -->
<div class="max-w-2xl mx-auto py-8">
  <h1 class="text-3xl font-bold">✅ Todo App with SSR Islands</h1>

  <%# Island コンポーネント: SSR + Client Hydration %>
  <%= island "TodoStats", @stats %>
  <%= island "AddTodoForm", {} %>
  <%= island "TodoList", { todos: @todos.map { |t| t.attributes.slice("id", "title", "completed") } } %>
</div>
```

### Island Component (Preact)

```jsx
// app/islands/TodoItem.jsx
import { h } from "preact";
import { useState } from "preact/hooks";

export function TodoItem({ id, title, completed: initialCompleted }) {
  const [completed, setCompleted] = useState(initialCompleted);

  const handleToggle = async () => {
    setCompleted(!completed);  // Optimistic UI update
    await fetch(`/todos/${id}/toggle`, { method: 'PATCH' });
    window.dispatchEvent(new CustomEvent('todo:toggled'));
  };

  return (
    <li className={`p-3 ${completed ? 'bg-green-50' : 'bg-white'}`}>
      <button onClick={handleToggle} className="mr-3">
        {completed ? '✅' : '⭕'}
      </button>
      <span className={completed ? 'line-through text-gray-500' : ''}>
        {title}
      </span>
    </li>
  );
}
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
|-----|--------|
| rack | HTTP interface |
| puma | Web server |
| mustermann | Route matching |
| tilt + erubi | Template rendering |
| activerecord | ORM |
| thor | CLI |
| zeitwerk | Auto-loading |
| tailwindcss-ruby | CSS (no Node.js) |
| quickjs | SSR JavaScript runtime |

## 🗺️ Roadmap

- [x] **v0.1.0** - Foundation (Router, Controller, CLI)
- [x] **v0.2.0** - Developer Experience (Zeitwerk, Error pages)
- [x] **v0.3.0** - Security (CSRF, Session, Flash)
- [x] **v0.4.0** - Production Ready (Assets, Logging)
- [x] **v0.5.0** - SSR Islands & Plugin System
- [ ] **v1.0.0** - Stable Release

詳細は [docs/development/ROADMAP.md](docs/development/ROADMAP.md) を参照してください。

## 🔒 Security

セキュリティは重要です。Salvia.rb を使用する前に、以下のドキュメントを確認してください:

- **[セキュリティガイド](docs/security/SECURITY_GUIDE.md)** - 安全なアプリケーション開発のベストプラクティス
- **[セキュリティチェックリスト](docs/security/SECURITY_CHECKLIST.md)** - 開発・デプロイ時のチェック項目

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

