# Salvia.rb Reference Guide

> 🌿 Salvia.rb v0.1.0 Official Reference

---

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [CLI Commands](#cli-commands)
4. [Routing](#routing)
5. [Controllers](#controllers)
6. [Views](#views)
7. [Helpers](#helpers)
8. [SSR Islands](#ssr-islands)
9. [Database](#database)
10. [Testing](#testing)
11. [Deployment](#deployment)

---

## Installation

### Install the Gem

```bash
gem install salvia_rb
```

### Using with Bundler

```ruby
# Gemfile
gem "salvia_rb"
```

### Requirements

- Ruby 3.1+
- Deno (for SSR build)
- SQLite3 (default) or PostgreSQL/MySQL

---

## Configuration

### Zero Configuration Startup

Salvia works without configuration:

```ruby
# config.ru (just 3 lines!)
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

### Configuration Options

```ruby
# config/environment.rb or config.ru
require "salvia_rb"

Salvia.configure do |config|
  # SSR Islands settings
  config.ssr_bundle_path = "vendor/server/ssr_bundle.js"
  config.island_inspector = nil  # nil = auto (development only)

  # Database settings
  config.database_url = nil  # nil = database.yml or convention-based

  # Session settings
  config.session_secret = nil  # nil = env var or auto-generate
  config.session_key = nil     # nil = "_#{app_name}_session"

  # Server settings
  config.default_server = nil  # nil = dev: puma, prod: falcon

  # Additional autoload paths
  config.autoload_paths = []

  # Log level
  config.log_level = nil  # nil = dev: debug, prod: info

  # Security settings
  config.csrf_enabled = true
  config.static_files_enabled = true
end

run Salvia::Application.new
```

### Configuration Class API

| Option | Default | Description |
|--------|---------|-------------|
| `ssr_bundle_path` | `vendor/server/ssr_bundle.js` | SSR bundle file path |
| `island_inspector` | `nil` (auto) | Enable/disable Island Inspector |
| `database_url` | `nil` | Database URL |
| `session_secret` | `nil` (auto) | Session encryption key |
| `session_key` | `nil` (auto) | Session cookie name |
| `default_server` | `nil` (auto) | Default server |
| `autoload_paths` | `[]` | Additional autoload paths |
| `log_level` | `nil` (auto) | Log level |
| `csrf_enabled` | `true` | Enable CSRF protection |
| `static_files_enabled` | `true` | Enable static file serving |

### Environment Variables

Salvia automatically loads `.env` files:

```bash
# Load order (later files override):
# 1. .env                    - Default values
# 2. .env.local              - Local overrides (gitignored)
# 3. .env.{RACK_ENV}         - Environment-specific (.env.production)
```

```bash
# .env.example
RACK_ENV=development
SESSION_SECRET=your-secret-here
DATABASE_URL=sqlite3:db/development.sqlite3
```

### Environment Methods

```ruby
Salvia.env           # => "development"
Salvia.development?  # => true
Salvia.production?   # => false
Salvia.test?         # => false
Salvia.root          # => "/path/to/app"
Salvia.logger        # => Logger instance
```

---

## CLI Commands

### Application Generation

```bash
# Create new app (interactive)
salvia new APP_NAME

# With options
salvia new APP_NAME --template=full --islands
salvia new APP_NAME --template=api --skip-prompts
salvia new APP_NAME --template=minimal
```

**Template options:**
- `full` - Full stack (ERB + Database + Views)
- `api` - API only (JSON responses, no views)
- `minimal` - Minimal (bare Rack app)

### Code Generation

```bash
# Generate controller
salvia generate controller NAME [actions]
salvia g controller posts index show create

# Generate model
salvia g model NAME [fields]
salvia g model post title:string body:text published:boolean

# Generate migration
salvia g migration NAME [fields]
salvia g migration add_user_id_to_posts user_id:integer
```

### Development Server

```bash
# Start server
salvia server
salvia s
salvia s -p 3000 -b 0.0.0.0

# Development mode (server + CSS + SSR watch)
salvia dev
salvia dev -p 3000

# Console
salvia console
salvia c
```

### Database

```bash
salvia db:create      # Create database
salvia db:drop        # Drop database
salvia db:migrate     # Run migrations
salvia db:rollback    # Rollback
salvia db:rollback -s 3  # Rollback 3 steps
salvia db:setup       # Create + migrate
```

### Assets

```bash
# Tailwind CSS
salvia css:build      # Build CSS
salvia css:watch      # Watch CSS

# SSR Islands
salvia ssr:build      # Build SSR bundle
salvia ssr:watch      # Watch SSR

# Asset precompilation (production)
salvia assets:precompile
```

### Utilities

```bash
salvia routes         # Display routes
salvia version        # Display version
```

---

## Routing

### Basic Routes

```ruby
# config/routes.rb
Salvia::Router.draw do
  # Root route
  root to: "home#index"

  # HTTP method routes
  get "/about", to: "pages#about"
  get "/posts/:id", to: "posts#show"
  post "/posts", to: "posts#create"
  put "/posts/:id", to: "posts#update"
  patch "/posts/:id", to: "posts#update"
  delete "/posts/:id", to: "posts#destroy"
end
```

### RESTful Resources

```ruby
resources :posts
# Generated routes:
#   GET    /posts          → posts#index
#   GET    /posts/new      → posts#new
#   POST   /posts          → posts#create
#   GET    /posts/:id      → posts#show
#   GET    /posts/:id/edit → posts#edit
#   PATCH  /posts/:id      → posts#update
#   DELETE /posts/:id      → posts#destroy

# Limited actions
resources :posts, only: [:index, :show]
resources :posts, except: [:destroy]
```

### Nested Resources

```ruby
resources :posts do
  resources :comments
end
# /posts/:post_id/comments/:id
```

### Named Routes

```ruby
# Route definition
get "/about", to: "pages#about", as: "about"

# Use in controller/view
posts_path          # => "/posts"
post_path(1)        # => "/posts/1"
new_post_path       # => "/posts/new"
edit_post_path(1)   # => "/posts/1/edit"
root_path           # => "/"
about_path          # => "/about"
```

### Routing DSL API

| Method | Description |
|--------|-------------|
| `root to: "controller#action"` | Root route |
| `get path, to: "controller#action"` | GET request |
| `post path, to: "controller#action"` | POST request |
| `put path, to: "controller#action"` | PUT request |
| `patch path, to: "controller#action"` | PATCH request |
| `delete path, to: "controller#action"` | DELETE request |
| `resources :name` | RESTful resources |
| `resources :name, only: [...]` | Limited actions |
| `resources :name, except: [...]` | Excluded actions |

---

## Controllers

### Basic Structure

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.all
    # render "posts/index" is called automatically
  end

  def show
    @post = Post.find(params["id"])
  end

  def create
    @post = Post.create!(post_params)
    flash[:notice] = "Post created successfully"
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

### Available Methods

| Method | Description |
|--------|-------------|
| `params` | Request parameters (merged URL + query + body) |
| `session` | Session hash |
| `flash` | Flash messages |
| `request` | Rack::Request object |
| `response` | Rack::Response object |
| `logger` | Logger instance |

### render Method

```ruby
# Template (with layout)
render "posts/show"

# Without layout
render "posts/show", layout: false

# Custom layout
render "posts/show", layout: "admin"

# Custom status code
render "posts/show", status: 201

# Local variables
render "posts/show", locals: { featured: true }

# Partial (no layout, auto _ prefix)
render partial: "posts/post"

# Plain text
render plain: "Hello, World!"

# JSON response
render json: { data: @posts, count: @posts.size }
```

### redirect_to Method

```ruby
# Redirect to URL
redirect_to "/posts"

# Redirect to named route
redirect_to posts_path
redirect_to post_path(@post.id)

# Custom status code
redirect_to posts_path, status: 301

# POST/PATCH/DELETE redirects automatically use 303 (See Other)
# GET/HEAD redirects automatically use 302 (Found)
```

### Session

```ruby
# Set value
session[:user_id] = user.id

# Get value
current_user_id = session[:user_id]

# Delete value
session.delete(:user_id)
```

### Flash Messages

```ruby
def create
  @post = Post.create!(params["post"])
  flash[:notice] = "Post created successfully"
  redirect_to posts_path
end

def update
  unless valid?
    flash.now[:alert] = "There are errors"  # Current request only
    render "posts/edit"
  end
end
```

---

## Views

### Layouts

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

### Templates

```erb
<!-- app/views/posts/index.html.erb -->
<h1>Posts</h1>

<ul>
  <% @posts.each do |post| %>
    <li>
      <%= link_to post.title, post_path(post.id) %>
    </li>
  <% end %>
</ul>

<%= link_to "New Post", new_post_path, class: "btn" %>
```

### Partials

```erb
<!-- app/views/posts/_post.html.erb -->
<article class="post">
  <h2><%= post.title %></h2>
  <p><%= post.body %></p>
</article>

<!-- Usage -->
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
<!-- Usage in views -->
<%= component "user_card", user: @user %>
```

---

## Helpers

### Tag Helpers

```ruby
tag(:div, class: "container") { "Content" }
# => <div class="container">Content</div>

tag(:input, type: "text", name: "title")
# => <input type="text" name="title">

# data attributes
tag(:div, data: { id: 1, action: "click" }) { "Click" }
# => <div data-id="1" data-action="click">Click</div>
```

### Link Helpers

```ruby
link_to "Home", "/"
# => <a href="/">Home</a>

link_to "Post", post_path(1), class: "btn"
# => <a href="/posts/1" class="btn">Post</a>
```

### Form Helpers

```ruby
# Form start
form_tag("/posts", method: :post)
# => <form action="/posts" method="post">
#    <input type="hidden" name="authenticity_token" value="...">

# For PUT/PATCH/DELETE
form_tag(post_path(1), method: :patch)
# => <form action="/posts/1" method="post">
#    <input type="hidden" name="_method" value="patch">

# Form end
form_close
# => </form>
```

### CSRF Helpers

```ruby
csrf_token          # => "abc123..."
csrf_meta_tags      # => <meta name="csrf-token" content="abc123...">
csrf_field          # => <input type="hidden" name="authenticity_token" value="...">
```

### Asset Helpers

```ruby
asset_path("stylesheets/tailwind.css")
# Development: "/assets/stylesheets/tailwind.css"
# Production: "/assets/stylesheets/tailwind-abc123.css" (hashed)
```

---

## SSR Islands

### Creating an Island Component

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

### Using in ERB

```erb
<h1>Counter Demo</h1>

<%# SSR + Client Hydration %>
<%= island "Counter", { initialCount: 10 } %>
```

### island Helper Options

```ruby
island "Counter", { count: 5 }
island "Counter", { count: 5 }, ssr: false      # Disable SSR
island "Counter", { count: 5 }, hydrate: false  # Disable hydration
island "Counter", { count: 5 }, tag: :section   # Custom tag
```

### SSR Build

```bash
salvia ssr:build   # Build
salvia ssr:watch   # Watch mode
salvia dev         # Server + SSR watch
```

### How It Works

```
1. SSR: Render Preact to HTML with QuickJS (0.3ms/render)
2. HTML: Embed in ERB
3. Hydrate: Client-side hydrate()
4. Interactive: Clicks and inputs work
```

---

## Database

### Configuration

```yaml
# config/database.yml
development:
  adapter: sqlite3
  database: db/development.sqlite3

production:
  adapter: postgresql
  url: <%= ENV['DATABASE_URL'] %>
```

### Migrations

```bash
salvia g migration create_posts title:string body:text
salvia db:migrate
salvia db:rollback
```

### Models

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  validates :title, presence: true
  has_many :comments
end
```

---

## Testing

### Setup

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

### Controller Tests

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

## Deployment

### Environment Variables (Production)

```bash
export RACK_ENV=production
export SESSION_SECRET=your-secure-secret-min-64-chars
export DATABASE_URL=postgresql://user:pass@host:5432/dbname
```

### Docker

```bash
docker compose up              # Development
docker build -t myapp .        # Production build
docker run -p 9292:9292 myapp  # Run
```

### Security Checklist

- [ ] CSRF tokens on all forms
- [ ] Escape all user output
- [ ] Parameterized SQL queries
- [ ] Secure session cookie settings
- [ ] HTTPS in production

---

*Last updated: 2025-12-10 (v0.1.0)*
