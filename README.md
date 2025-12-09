<p align="center">
  <img src="https://img.shields.io/badge/Ruby-3.1+-CC342D?style=flat-square&logo=ruby" alt="Ruby">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/Version-0.1.0-6A5ACD?style=flat-square" alt="Version">
  <img src="https://img.shields.io/gem/v/salvia_rb?style=flat-square&color=ff6347" alt="Gem">
</p>

# 🌿 Salvia.rb

> **"Wisdom for Rubyists."**
>
> A small, understandable Ruby MVC framework

**SSR Islands Architecture** × **Tailwind** × **ActiveRecord** combined into a simple and clear Ruby Web framework.

## Features

- **🚀 Zero Configuration** - Works out of the box, customizable when needed
- **Server-Rendered (HTML) First** - Return HTML, not JSON APIs
- **🏝️ SSR Islands Architecture** - Server-side render Preact components with QuickJS
- **Rails-like DSL** - Familiar `resources`, `root to:` routing
- **ActiveRecord Integration** - Use models like Rails
- **🐳 Docker Ready** - Auto-generated Dockerfile and docker-compose.yml
- **No Node.js Required** - QuickJS for SSR, Deno for build

## Installation

```ruby
gem "salvia_rb"
```

## Quick Start

```bash
# Install the gem
gem install salvia_rb

# Create a new app
salvia new myapp
cd myapp

# Setup and start
bundle install
salvia ssr:build   # Build SSR bundle (requires Deno)
salvia server      # Start server (Puma in dev, Falcon in prod)
```

Open http://localhost:9292 in your browser.

### Zero Configuration

Salvia works with minimal setup:

```ruby
# config.ru (3 lines!)
require "salvia_rb"
Salvia.configure { |c| c.root = __dir__ }
run Salvia::Application.new
```

### One-liner Mode

```ruby
# app.rb
require "salvia_rb"
Salvia.run!  # Auto-selects server: Puma (dev) or Falcon (prod)
```

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
│       └── Counter.js
├── vendor/server/
│   └── ssr_bundle.js           # SSR bundle (generated)
├── config/
│   ├── database.yml
│   ├── environment.rb
│   └── routes.rb
├── db/
│   └── migrate/
├── public/
│   └── assets/
├── config.ru                   # 3 lines!
├── Gemfile
├── Dockerfile                  # Auto-generated
└── docker-compose.yml          # Auto-generated
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
salvia ssr:build
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
| `salvia server` / `salvia s` | Start server (Puma dev / Falcon prod) |
| `salvia dev` | Start server + CSS watch + SSR watch |
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
| `salvia g controller NAME` | Generate controller |
| `salvia g model NAME` | Generate model |

## Environment Variables

Salvia automatically loads `.env` files:

```bash
# Load order (later files override):
# 1. .env                    - Default values
# 2. .env.local              - Local overrides (gitignored)
# 3. .env.{RACK_ENV}         - Environment-specific (.env.production)
```

```bash
# .env.example (generated with your app)
RACK_ENV=development
SESSION_SECRET=your-secret-here
DATABASE_URL=sqlite3:db/development.sqlite3
```

## Docker

Generated apps include Docker support:

```bash
# Development
docker compose up

# Production
docker build -t myapp .
docker run -p 9292:9292 -e RACK_ENV=production myapp
```

## Requirements

- Ruby 3.1+
- Deno (for SSR build)
- SQLite3 (default) or PostgreSQL/MySQL

## License

MIT License - See [LICENSE](LICENSE) for details.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/genfuru011/Salvia).

---

<p align="center">
  <strong>🌿 Salvia.rb</strong><br>
  <em>"Simple, like a flower. Solid, like a gem."</em>
</p>
