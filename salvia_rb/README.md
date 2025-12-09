<p align="center">
  <img src="https://img.shields.io/badge/Ruby-3.1+-CC342D?style=flat-square&logo=ruby" alt="Ruby">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/Version-0.5.0-6A5ACD?style=flat-square" alt="Version">
</p>

# 🌿 Salvia.rb

> **"Wisdom for Rubyists."**
>
> A small, understandable Ruby MVC framework

**SSR Islands Architecture** × **Tailwind** × **ActiveRecord** combined into a simple and clear Ruby Web framework.

## Features

- **Server-Rendered (HTML) First** - Return HTML, not JSON APIs
- **🏝️ SSR Islands Architecture** - Server-side render Preact components with QuickJS
- **Rails-like DSL** - Familiar `resources`, `root to:` routing
- **ActiveRecord Integration** - Use models like Rails
- **No Node.js Required** - QuickJS for SSR, Deno for build (production needs no Node)

## Installation

```ruby
gem "salvia_rb"
```

## Quick Start

```bash
# Create a new app
salvia new myapp
cd myapp

# Setup
bundle install
salvia db:setup
salvia css:build

# Build SSR bundle
deno run -A bin/build_ssr.ts

# Start server
salvia server
```

Open http://localhost:9292 in your browser.

## Directory Structure

```
myapp/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── home_controller.rb
│   ├── models/
│   │   └── application_record.rb
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.html.erb
│   │   └── home/
│   │       └── index.html.erb
│   └── islands/                # 🏝️ Island components
│       └── Counter.jsx
├── bin/
│   └── build_ssr.ts            # Deno build script
├── vendor/server/
│   └── ssr_bundle.js           # SSR bundle
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

## Routing

```ruby
# config/routes.rb
Salvia::Router.draw do
  root to: "home#index"

  get "/about", to: "pages#about"

  resources :posts, only: [:index, :show, :create]
end
```

## Controller

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.order(created_at: :desc)
  end

  def create
    @post = Post.create!(title: params["title"])
    render "posts/_post", locals: { post: @post }
  end
end
```

## 🏝️ SSR Islands

Salvia's Islands Architecture supports server-side rendering (SSR).

### Create an Island Component

```jsx
// app/islands/Counter.jsx
import { h } from "preact";
import { useState } from "preact/hooks";

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

### Use in ERB

```erb
<!-- app/views/home/index.html.erb -->
<h1>Counter Demo</h1>

<%# SSR + Client Hydration %>
<%= island "Counter", { initialCount: 10 } %>
```

### Build SSR Bundle

```bash
deno run -A bin/build_ssr.ts
```

### How It Works

```
1. SSR: Render Preact components with QuickJS (0.3ms/render)
2. HTML: Embed rendered result in ERB
3. Hydrate: Client-side Preact hydrate()
4. Interactive: Clicks and inputs work
```

## CLI Commands

| Command | Description |
|---------|-------------|
| `salvia new APP_NAME` | Create a new application |
| `salvia server` / `salvia s` | Start development server |
| `salvia dev` | Start server + SSR watch |
| `salvia console` / `salvia c` | Start IRB console |
| `salvia db:create` | Create database |
| `salvia db:migrate` | Run migrations |
| `salvia db:rollback` | Rollback last migration |
| `salvia db:setup` | Create database and run migrations |
| `salvia css:build` | Build Tailwind CSS |
| `salvia css:watch` | Watch and rebuild CSS |
| `salvia ssr:build` | Build SSR bundle |
| `salvia ssr:watch` | Watch and rebuild SSR |
| `salvia routes` | Display routes |

## Requirements

- Ruby 3.1+
- Deno (for SSR build)
- SQLite3 (default) or PostgreSQL/MySQL

## License

MIT License

## Contributing

Bug reports and pull requests are welcome!

---

*"Simple, like a flower. Solid, like a gem."* 🌿
