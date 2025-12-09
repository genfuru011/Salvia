# Salvia vs Rails Syntax Comparison

A quick reference for Rails developers. About 80% of the syntax is the same!

---

## 📊 Overview Comparison

| Feature | Rails | Salvia |
|---------|-------|--------|
| **Size** | Full-stack (large) | Micro (lightweight) |
| **Frontend** | Hotwire / Turbo | Preact Islands |
| **JS Build** | esbuild / Node | Deno |
| **SSR** | Complex | Simple with QuickJS |
| **ORM** | ActiveRecord | ActiveRecord |
| **Templates** | ERB | ERB |
| **Configuration** | Heavy | Minimal |
| **Startup Speed** | Slow | Fast |

---

## 🛤️ Routing

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
  
  # Define resources manually
  get "/posts", "posts#index"
  get "/posts/drafts", "posts#drafts"
  get "/posts/:id", "posts#show"
  post "/posts", "posts#create"
  patch "/posts/:id", "posts#update"
  delete "/posts/:id", "posts#destroy"
  patch "/posts/:id/publish", "posts#publish"
  
  get "/about", "pages#about", as: :about
  
  # namespace is manual
  get "/admin/users", "admin/users#index"
end
```

**Difference:** No `resources` helper. Simple manual definition.

---

## 🎮 Controllers

### Basic Structure

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
    redirect_to @post, notice: "Created successfully"
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
    flash[:notice] = "Created successfully"
    redirect_to post_path(id: @post.id)
  end
end
```

**Differences:**
- No `before_action` (planned for future)
- No Strong Parameters (simple direct access)
- `redirect_to @post` → `redirect_to post_path(id: @post.id)`

### Rendering

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
redirect_to @post, notice: "Success"

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
redirect_to post_path(id: @post.id)  # notice via flash separately
```

### Parameters

```ruby
# Rails
params[:id]                         # URL params
params[:post][:title]               # Nested params
params.require(:post).permit(:title) # Strong Parameters

# Salvia
params[:id]                         # URL params
params[:title]                      # JSON body auto-parsed
# No Strong Parameters - direct access
```

### Session & Flash

```ruby
# Rails
session[:user_id] = user.id
session.delete(:user_id)
flash[:notice] = "Success"
flash[:alert] = "Error"
flash.now[:notice] = "Temporary"

# Salvia
session[:user_id] = user.id
session.delete(:user_id)
flash[:notice] = "Success"
flash[:error] = "Error"
# flash.now not supported
```

### CSRF

```ruby
# Rails - Controller
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# Salvia - Automatic (middleware handles it)
class ApplicationController < Salvia::Controller
  # Automatically protected
end
```

```ruby
# Get CSRF token
# Rails
form_authenticity_token

# Salvia
csrf_token
```

---

## 📄 Views / Templates

### Links

```erb
<%# Rails %>
<%= link_to "All Posts", posts_path %>
<%= link_to "Details", @post %>
<%= link_to "Details", post_path(@post) %>
<%= link_to "Delete", @post, method: :delete, data: { confirm: "Are you sure?" } %>

<%# Salvia %>
<a href="<%= posts_path %>">All Posts</a>
<a href="<%= post_path(id: @post.id) %>">Details</a>
<%# method: :delete requires JavaScript %>
```

### Forms

```erb
<%# Rails %>
<%= form_with model: @post do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body %>
  <%= f.submit "Save" %>
<% end %>

<%= form_with url: search_path, method: :get do |f| %>
  <%= f.text_field :q %>
<% end %>

<%# Salvia %>
<form action="<%= posts_path %>" method="post">
  <%= csrf_input_tag %>
  <input type="text" name="title" value="<%= @post&.title %>">
  <textarea name="body"><%= @post&.body %></textarea>
  <button type="submit">Save</button>
</form>

<form action="<%= search_path %>" method="get">
  <input type="text" name="q">
</form>
```

### Partials

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
<%# spacer_template not supported %>
```

### Layout

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

### CSRF Tags

```erb
<%# Rails %>
<%= csrf_meta_tags %>
<%# Output: <meta name="csrf-param" ...><meta name="csrf-token" ...> %>

<%= form_with ... %>  <%# Auto-inserts hidden field %>

<%# Salvia %>
<%= csrf_meta_tag %>
<%# Output: <meta name="csrf-token" ...> %>

<form ...>
  <%= csrf_input_tag %>  <%# Add manually %>
</form>
```

---

## 🏝️ Frontend

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
<%# Call Island from ERB %>
<%= island "Counter", count: 0 %>

<%# Pass props %>
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
// app/islands/PostList.jsx - API integration
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
          <button onClick={() => deletePost(post.id)}>Delete</button>
        </li>
      ))}
    </ul>
  );
}
```

**Differences:**
- Rails: HTML-centric, server rendering
- Salvia: React-style, component-oriented, SSR + hydration

---

## 🗄️ Models

```ruby
# Rails (same!)
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

# Salvia (same!)
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

**Difference:** None! Uses ActiveRecord directly.

---

## 🔄 Migrations

```ruby
# Rails (same!)
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

# Salvia (same!)
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

**Difference:** None!

---

## 🔧 CLI Commands

| Feature | Rails | Salvia |
|---------|-------|--------|
| New project | `rails new app` | `salvia new app` |
| Server | `rails server` | `salvia server` |
| Console | `rails console` | `salvia console` |
| Generate model | `rails g model Post` | `salvia g model Post` |
| Generate controller | `rails g controller Posts` | `salvia g controller Posts` |
| Migrate | `rails db:migrate` | `salvia db:migrate` |
| Rollback | `rails db:rollback` | `salvia db:rollback` |
| Seed | `rails db:seed` | `salvia db:seed` |
| Routes | `rails routes` | `salvia routes` |

---

## ⚙️ Configuration Files

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

# SSR configuration
Salvia::SSR.configure(
  bundle_path: File.join(Salvia.root, "vendor/server/ssr_bundle.js"),
  development: Salvia.env == "development"
)

require_relative "routes"

# config/routes.rb
Salvia::Router.define do
  # ...
end

# config/database.yml (same!)
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
gem "quickjs"  # For SSR

group :development do
  gem "debug"
end
```

**Difference:** Salvia has fewer dependencies!

---

## 🚀 Migration Checklist

Changes needed when migrating Rails → Salvia:

### ✅ Works as-is
- [x] Models (ActiveRecord)
- [x] Migrations
- [x] Validations
- [x] Associations
- [x] Scopes
- [x] Callbacks
- [x] ERB basic syntax
- [x] Session
- [x] Flash

### 🔄 Needs rewriting
- [ ] `resources` → Manual route definition
- [ ] `link_to` → `<a href="">` tags
- [ ] `form_with` → `<form>` tags + `csrf_input_tag`
- [ ] `before_action` → Execute in each action
- [ ] Strong Parameters → Direct `params[:key]`
- [ ] `redirect_to @post` → `redirect_to post_path(id: @post.id)`
- [ ] Hotwire/Turbo → Preact Islands

### ❌ Not supported (planned for future)
- [ ] Action Cable (WebSocket)
- [ ] Active Job (Background jobs)
- [ ] Action Mailer (Email)
- [ ] Active Storage (File uploads)

---

## 💡 Why Salvia?

| Aspect | Rails | Salvia |
|--------|-------|--------|
| **Learning Curve** | High | Low (Rails experience = instant productivity) |
| **Startup Speed** | Slow | Fast |
| **Memory Usage** | High | Low |
| **Frontend** | HTML-centric | React-style components |
| **SSR** | Complex | Simple (QuickJS built-in) |
| **Small Projects** | Overkill | Perfect |
| **Large Projects** | Perfect | Growing |

**Conclusion:** Leverage Rails' best practices with a modern frontend development experience! 🌿
