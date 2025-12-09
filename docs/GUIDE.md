# Salvia.rb Guide

> Getting started, usage, and security best practices

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Routing](#routing)
3. [Controllers](#controllers)
4. [Views & Templates](#views--templates)
5. [Database](#database)
6. [SSR Islands](#ssr-islands)
7. [Security](#security)
8. [Testing](#testing)
9. [Deployment](#deployment)

---

## Quick Start

### Installation

```bash
gem install salvia_rb
```

### Create a New Application

```bash
salvia new myapp
cd myapp
bundle install
```

### Start the Server

```bash
salvia server
# or
salvia s
```

Visit `http://localhost:9292`

### Project Structure

```
myapp/
├── app/
│   ├── controllers/     # Request handlers
│   ├── models/          # ActiveRecord models
│   ├── views/           # ERB templates
│   └── islands/         # Preact components (optional)
├── config/
│   ├── routes.rb        # URL routing
│   ├── database.yml     # Database config
│   └── environment.rb   # App initialization
├── db/
│   └── migrate/         # Database migrations
├── public/              # Static files
└── test/                # Tests
```

---

## Routing

### Basic Routes

```ruby
# config/routes.rb
Salvia::Router.draw do
  root to: "home#index"
  
  get "/about", to: "pages#about"
  get "/posts/:id", to: "posts#show"
  post "/posts", to: "posts#create"
end
```

### Resourceful Routes

```ruby
resources :posts
# Creates:
#   GET    /posts          → posts#index
#   GET    /posts/new      → posts#new
#   POST   /posts          → posts#create
#   GET    /posts/:id      → posts#show
#   GET    /posts/:id/edit → posts#edit
#   PATCH  /posts/:id      → posts#update
#   DELETE /posts/:id      → posts#destroy

resources :posts, only: [:index, :show]
resources :posts, except: [:destroy]
```

### Nested Resources

```ruby
resources :posts do
  resources :comments
end
# /posts/:post_id/comments
```

### Named Routes

```ruby
# In controller/view:
posts_path        # /posts
post_path(1)      # /posts/1
new_post_path     # /posts/new
edit_post_path(1) # /posts/1/edit
```

---

## Controllers

### Basic Controller

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.all
    render "posts/index"
  end
  
  def show
    @post = Post.find(params["id"])
    render "posts/show"
  end
  
  def create
    @post = Post.create!(params["post"])
    redirect_to post_path(@post.id)
  end
end
```

### Available Methods

| Method | Description |
|--------|-------------|
| `params` | Request parameters (merged URL, query, body) |
| `session` | Session hash |
| `flash` | Flash messages (`flash[:notice]`, `flash[:alert]`) |
| `render(template)` | Render ERB template |
| `redirect_to(url)` | Redirect response |
| `request` | Rack::Request object |
| `response` | Rack::Response object |

### Render Options

```ruby
render "posts/show"                    # Template with layout
render "posts/show", layout: false     # No layout
render "posts/show", status: 201       # Custom status
render partial: "posts/post"           # Partial (no layout)
render plain: "Hello"                  # Plain text
render json: { data: @posts }          # JSON response
```

### Flash Messages

```ruby
def create
  @post = Post.create!(params["post"])
  flash[:notice] = "Post created successfully"
  redirect_to posts_path
end

def update
  flash.now[:alert] = "Validation failed"  # Current request only
  render "posts/edit"
end
```

---

## Views & Templates

### Layouts

```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <title>My App</title>
  <link rel="stylesheet" href="/assets/stylesheets/tailwind.css">
</head>
<body>
  <% if flash[:notice] %>
    <div class="bg-green-100 p-4"><%= flash[:notice] %></div>
  <% end %>
  
  <%= yield %>
</body>
</html>
```

### Templates

```erb
<!-- app/views/posts/index.html.erb -->
<h1>Posts</h1>

<% @posts.each do |post| %>
  <article>
    <h2><%= post.title %></h2>
    <p><%= post.body %></p>
  </article>
<% end %>
```

### Partials

```erb
<!-- app/views/posts/_post.html.erb -->
<article class="post">
  <h2><%= post.title %></h2>
  <p><%= post.body %></p>
</article>

<!-- Usage -->
<%= render "posts/post", post: @post %>

<!-- Loop -->
<% @posts.each do |post| %>
  <%= render "posts/post", post: post %>
<% end %>
```

### Helpers

```ruby
# Tag helpers
link_to "Home", "/"
link_to "Post", post_path(1), class: "btn"

# Form helpers
form_tag("/posts", method: "post") do
  # form fields
end
form_close

# Asset helpers
asset_path("stylesheets/tailwind.css")
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
# Create migration file
touch db/migrate/20250101000000_create_posts.rb
```

```ruby
# db/migrate/20250101000000_create_posts.rb
class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.timestamps
    end
  end
end
```

```bash
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

## SSR Islands

### Overview

SSR Islands allow you to embed interactive Preact components in server-rendered HTML. Components are rendered on the server with QuickJS and hydrated on the client.

### Creating an Island

```jsx
// app/islands/Counter.jsx
import { h } from 'preact';
import { useState } from 'preact/hooks';

export default function Counter({ initialCount = 0 }) {
  const [count, setCount] = useState(initialCount);
  
  return (
    <div class="counter">
      <p>Count: {count}</p>
      <button onClick={() => setCount(c => c + 1)}>+</button>
      <button onClick={() => setCount(c => c - 1)}>-</button>
    </div>
  );
}
```

### Using in ERB

```erb
<h1>My Page</h1>

<p>Static content here...</p>

<%= island "Counter", { initialCount: 10 } %>

<p>More static content...</p>
```

### Building Islands

```bash
salvia islands:build
```

This generates:
- `vendor/server/ssr_bundle.js` - Server-side bundle (QuickJS)
- `public/assets/javascripts/islands.js` - Client-side bundle (hydration)

---

## Security

### CSRF Protection

CSRF protection is enabled by default via `Rack::Protection`.

```erb
<!-- In layout head -->
<%= csrf_meta_tags %>
```

```javascript
// For JavaScript requests
const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
fetch('/posts', {
  method: 'POST',
  headers: {
    'X-CSRF-Token': csrfToken,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(data)
});
```

### XSS Prevention

ERB auto-escapes output by default:

```erb
<!-- Safe: automatically escaped -->
<p><%= user_input %></p>

<!-- Dangerous: raw HTML (use only with trusted content) -->
<p><%== trusted_html %></p>
```

### SQL Injection Prevention

Always use parameterized queries:

```ruby
# ✅ Safe
User.where("name = ?", params[:name])
User.where(name: params[:name])

# ❌ Dangerous
User.where("name = '#{params[:name]}'")
```

### Session Security

```ruby
# config.ru
use Rack::Session::Cookie,
  key: "_myapp_session",
  secret: ENV.fetch("SESSION_SECRET"),
  same_site: :lax,
  httponly: true,
  secure: ENV['RACK_ENV'] == 'production'
```

### Password Hashing

```ruby
# Gemfile
gem 'bcrypt'

# Model
class User < ApplicationRecord
  has_secure_password
  validates :password, length: { minimum: 8 }
end

# Controller
user.authenticate(params[:password])
```

### Security Headers

```ruby
# config.ru or middleware
response['X-Content-Type-Options'] = 'nosniff'
response['X-Frame-Options'] = 'DENY'
response['X-XSS-Protection'] = '1; mode=block'
response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
```

### Security Checklist

- [ ] CSRF tokens on all forms
- [ ] Escape all user output in templates
- [ ] Use parameterized SQL queries
- [ ] Hash passwords with bcrypt
- [ ] Validate file uploads (type, size)
- [ ] Set secure session cookie options
- [ ] Keep dependencies updated (`bundle-audit`)
- [ ] Use HTTPS in production

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
    Rack::Builder.parse_file("config.ru").first
  end
end
```

### Controller Tests

```ruby
# test/controllers/posts_controller_test.rb
require "test_helper"

class PostsControllerTest < SalviaTest
  def test_index
    get "/posts"
    assert last_response.ok?
    assert_includes last_response.body, "Posts"
  end
  
  def test_create
    post "/posts", { post: { title: "Test" } }
    assert last_response.redirect?
  end
end
```

### Running Tests

```bash
ruby -Itest test/controllers/posts_controller_test.rb
# or
rake test
```

---

## Deployment

### Environment Variables

```bash
# Required in production
export RACK_ENV=production
export SESSION_SECRET=your-secure-secret
export DATABASE_URL=postgresql://...
```

### Procfile (for Heroku, Render, etc.)

```
web: bundle exec rackup -p $PORT -E production
```

### Build Steps

```bash
bundle install --without development test
salvia css:build
salvia islands:build  # if using Islands
salvia db:migrate
```

### Nginx Configuration

```nginx
upstream salvia {
  server 127.0.0.1:9292;
}

server {
  listen 80;
  server_name example.com;
  
  location /assets {
    root /var/www/myapp/public;
    expires max;
  }
  
  location / {
    proxy_pass http://salvia;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

---

## CLI Reference

```bash
salvia new APP_NAME      # Create new application
salvia server (s)        # Start development server
salvia console (c)       # Start IRB console
salvia routes            # List all routes
salvia db:create         # Create database
salvia db:drop           # Drop database
salvia db:migrate        # Run migrations
salvia db:rollback       # Rollback last migration
salvia db:setup          # Create and migrate
salvia css:build         # Build Tailwind CSS
salvia css:watch         # Watch and build CSS
salvia islands:build     # Build SSR Islands bundle
salvia version           # Show version
```

---

*Last updated: 2025-12 (v0.7.0)*
