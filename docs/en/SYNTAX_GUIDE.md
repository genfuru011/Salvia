# Salvia Syntax Guide

A comprehensive guide to Salvia framework syntax and patterns.

## 📁 Project Structure

```
my_app/
├── app/
│   ├── controllers/      # Controllers
│   ├── models/           # ActiveRecord models
│   ├── views/            # ERB templates
│   │   └── layouts/      # Layouts
│   ├── islands/          # Preact Islands (JSX)
│   └── assets/
│       └── stylesheets/  # CSS/Tailwind
├── config/
│   ├── environment.rb    # App configuration
│   ├── routes.rb         # Routing
│   └── database.yml      # Database config
├── db/
│   ├── migrate/          # Migrations
│   └── seeds.rb          # Seed data
├── public/               # Static files
├── vendor/               # Build artifacts
├── config.ru             # Rack config
├── Gemfile               # Ruby dependencies
└── deno.json             # Deno/Islands config
```

---

## 🛤️ Routing (config/routes.rb)

```ruby
Salvia::Router.define do
  # Root route
  root "home#index"                    # GET / → HomeController#index

  # RESTful routes
  get "/posts", "posts#index"          # GET /posts
  get "/posts/:id", "posts#show"       # GET /posts/123
  post "/posts", "posts#create"        # POST /posts
  patch "/posts/:id", "posts#update"   # PATCH /posts/123
  delete "/posts/:id", "posts#destroy" # DELETE /posts/123

  # Custom actions
  patch "/tasks/:id/toggle", "tasks#toggle"

  # Named routes (generates helpers)
  get "/about", "pages#about", as: :about
  # → about_path => "/about"
end
```

---

## 🎮 Controllers (app/controllers/)

```ruby
class PostsController < ApplicationController
  # Index
  def index
    @posts = Post.all.order(created_at: :desc)
  end

  # Show
  def show
    @post = Post.find(params[:id])
  end

  # Create (JSON API)
  def create
    post = Post.create!(
      title: params[:title],    # JSON body auto-parsed
      body: params[:body]
    )
    render json: post           # JSON response
  end

  # Update
  def update
    post = Post.find(params[:id])
    post.update!(title: params[:title])
    render json: post
  end

  # Destroy
  def destroy
    Post.find(params[:id]).destroy!
    render json: { success: true }
  end
end
```

### Rendering Options

```ruby
# Specify template
render "posts/show"

# Different template
render template: "shared/error"

# JSON response
render json: { data: @posts }

# Plain text
render plain: "Hello"

# Status code
render json: { error: "Not found" }, status: 404

# No layout
render layout: false

# Different layout
render layout: "admin"

# Redirect
redirect_to "/posts"
redirect_to posts_path
```

### Available Methods

```ruby
# Parameters
params[:id]          # URL params & JSON body
params[:title]

# Request
request.path         # "/posts/123"
request.method       # "GET", "POST", etc.
request.xhr?         # Ajax request?

# Session
session[:user_id]    # Session data
session[:user_id] = 123

# Flash messages
flash[:notice] = "Saved successfully"
flash[:error] = "An error occurred"

# CSRF
csrf_token           # Get token
csrf_meta_tag        # <meta name="csrf-token" ...>
```

---

## 📄 Views / Templates (app/views/)

### ERB Syntax

```erb
<%# Comment %>

<% Ruby code %>
<%= Output Ruby expression %>

<%# Conditionals %>
<% if @posts.any? %>
  <p>Posts exist</p>
<% else %>
  <p>No posts</p>
<% end %>

<%# Loops %>
<% @posts.each do |post| %>
  <div><%= post.title %></div>
<% end %>
```

### Helpers

```erb
<%# Route helpers %>
<a href="<%= posts_path %>">All Posts</a>
<a href="<%= post_path(id: @post.id) %>">Details</a>

<%# CSRF meta tag (add to layout) %>
<%= csrf_meta_tag %>

<%# Island components %>
<%= island "Counter", count: 5 %>
<%= island "TaskList", tasks: @tasks, csrf_token: @csrf_token %>

<%# Partials %>
<%= render partial: "posts/post", locals: { post: @post } %>

<%# Partials (collection) %>
<%= render partial: "posts/post", collection: @posts %>
```

### Layout (app/views/layouts/application.html.erb)

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

Preact-based interactive components.

### Basic Structure (Counter.jsx)

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

### API Integration (TaskList.jsx)

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
        'X-CSRF-Token': csrfToken  // CSRF token required
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

### Client-Only Island

Skip SSR for browser API dependencies:

```jsx
"client only";  // Add at file start

import { useState, useEffect } from 'preact/hooks';

export default function BrowserOnly() {
  const [width, setWidth] = useState(0);

  useEffect(() => {
    setWidth(window.innerWidth);  // window is browser-only
  }, []);

  return <p>Window width: {width}px</p>;
}
```

### Calling Islands from ERB

```erb
<%# Basic %>
<%= island "Counter", count: 10 %>

<%# Multiple props %>
<%= island "TaskList", tasks: @tasks, csrf_token: @csrf_token %>

<%# Disable SSR %>
<%= island "Chart", data: @data, ssr: false %>

<%# Disable hydration (static HTML only) %>
<%= island "StaticCard", title: "Hello", hydrate: false %>
```

---

## 🗄️ Models (app/models/)

ActiveRecord-based.

```ruby
class Post < ApplicationRecord
  # Validations
  validates :title, presence: true
  validates :body, length: { minimum: 10 }

  # Associations
  belongs_to :user
  has_many :comments, dependent: :destroy

  # Scopes
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
end
```

### Migrations (db/migrate/)

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

## ⚙️ Configuration Files

### config/environment.rb

```ruby
require "bundler/setup"
require "salvia_rb"

Salvia.root = File.expand_path("..", __dir__)
Salvia.env = ENV.fetch("RACK_ENV", "development")

# SSR configuration (when using Islands)
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
gem "quickjs"  # For SSR

group :development do
  gem "debug"
end
```

---

## 🔧 CLI Commands

```bash
# Create new project
salvia new my_app

# Start server
salvia server              # http://localhost:9292
salvia server -p 3000      # Specify port

# Database migrations
salvia db:migrate
salvia db:rollback
salvia db:seed

# Generators
salvia generate model Post title:string body:text
salvia generate controller Posts index show create

# Islands build
deno run -A vendor/scripts/build_ssr.ts
deno run -A vendor/scripts/build_ssr.ts --watch  # Watch mode
```

---

## 🔒 CSRF Protection

### Add meta tag to layout

```erb
<head>
  <%= csrf_meta_tag %>
</head>
```

### Pass CSRF token from controller

```ruby
def index
  @csrf_token = csrf_token
end
```

### API requests from Island

```jsx
await fetch('/api/endpoint', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken  // Token received via props
  },
  body: JSON.stringify(data)
});
```

---

## 💡 Tips

### Auto-reload in development

```bash
# Watch Islands in separate terminal
deno run -A vendor/scripts/build_ssr.ts --watch
```

### Debugging

```ruby
# Debug in controller
puts params.inspect
puts @posts.to_json

# binding.break (debug gem)
def show
  @post = Post.find(params[:id])
  binding.break  # Pause here
end
```

### Environment Variables (.env)

```bash
# .env
DATABASE_URL=sqlite3://db/production.sqlite3
SECRET_KEY_BASE=your-secret-key
```

```ruby
# Usage
ENV["DATABASE_URL"]
ENV.fetch("SECRET_KEY_BASE")
```

---

Now you understand Salvia's basic syntax and patterns! 🌿
