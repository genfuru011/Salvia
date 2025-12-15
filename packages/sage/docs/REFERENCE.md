# Sage Framework Reference Guide

Sage is a modern Ruby web framework designed for simplicity, performance, and seamless integration with modern frontend technologies. It combines the elegance of Ruby with the power of TypeScript and Deno for a superior developer experience.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Project Structure](#project-structure)
3. [Routing & Resources](#routing--resources)
4. [Frontend Integration (Deno)](#frontend-integration-deno)
5. [Database (ActiveRecord)](#database-activerecord)
6. [CLI Commands](#cli-commands)

---

## Getting Started

### Installation

```bash
gem install sage
```

### Creating a New Project

```bash
sage new my_app
cd my_app
bundle install
```

### Starting the Development Server

```bash
bundle exec sage dev
```

This starts the Sage server on port 3000 with live reloading and the Deno sidecar for SSR and asset compilation.

---

## Project Structure

```
my_app/
├── adapter/            # Deno Sidecar Adapter
│   ├── server.ts       # Deno Server Entry
│   ├── client.ts       # Client-side Entry
│   └── deno.json       # Import Map & Dependencies
├── app/
│   ├── models/         # ActiveRecord models
│   ├── resources/      # Sage resources (Controllers)
│   ├── pages/          # SSR Pages (TSX)
│   └── components/     # Shared Components (TSX)
├── config/
│   ├── application.rb  # App configuration
│   └── routes.rb       # Route definitions
├── db/                 # Database migrations and schema
├── public/             # Static assets
└── Gemfile
```

---

## Routing & Resources

Sage uses a resource-based routing system similar to Rails but with a more explicit syntax.

### Defining Routes (`config/routes.rb`)

```ruby
Sage::Router.draw do
  root to: "HomeResource"
  
  mount "/todos", to: "TodosResource"
  
  # Grouping routes
  group "/api" do
    mount "/users", to: "UsersResource"
  end
end
```

### Creating Resources (`app/resources/todos_resource.rb`)

Resources inherit from `Sage::Resource` and define handlers for HTTP verbs.

```ruby
class TodosResource < Sage::Resource
  # Standard HTTP handlers
  get "/" do |ctx|
    @todos = Todo.all
    # Render a Page (app/pages/Todos.tsx)
    ctx.render "Todos", todos: @todos
  end

  post "/" do |ctx|
    Todo.create(title: ctx.params[:title])
    ctx.redirect "/todos"
  end
  
  # Dynamic segments
  get "/:id" do |ctx|
    todo = Todo.find(ctx.params[:id])
    ctx.render "Todo", todo: todo
  end

  # Turbo Stream Response
  post "/:id/toggle" do |ctx|
    todo = Todo.find(ctx.params[:id])
    todo.update(completed: !todo.completed)
    
    # Render a Component (app/components/TodoItem.tsx) wrapped in a Turbo Stream
    ctx.turbo_stream :replace, "todo_#{todo.id}", "components/TodoItem", todo: todo
  end
end
```

---

## Frontend Integration (Deno)

Sage uses a Deno sidecar process to handle Server-Side Rendering (SSR) and on-demand asset compilation.

### Pages (`app/pages/`)

Pages are TSX components rendered on the server. They are the entry points for your views.

```tsx
// app/pages/Home.tsx
import { h } from "preact";

export default function Home({ title }: { title: string }) {
  return (
    <html>
      <head>
        <title>{title}</title>
        <script type="module" src="/assets/sage/client.js"></script>
      </head>
      <body>
        <h1>Hello, {title}!</h1>
      </body>
    </html>
  );
}
```

### Components (`app/components/`)

Components are reusable UI parts. They can be rendered as part of a page or individually via Turbo Streams.

```tsx
// app/components/TodoItem.tsx
import { h } from "preact";

export default function TodoItem({ todo }) {
  return (
    <div class={todo.completed ? "completed" : ""}>
      {todo.title}
    </div>
  );
}
```

### Managing Dependencies (`adapter/deno.json`)

You can add npm packages to `adapter/deno.json`. Sage automatically handles the resolution for both SSR (Deno) and Browser (via esm.sh).

```json
{
  "imports": {
    "preact": "npm:preact@10.19.6",
    "preact/": "npm:preact@10.19.6/",
    "@hotwired/turbo": "npm:@hotwired/turbo@8.0.4",
    "canvas-confetti": "npm:canvas-confetti@1.9.2"
  }
}
```

In your code:

```tsx
import confetti from "canvas-confetti";
```

### Client-Side Logic

Since Sage compiles `.tsx` files on demand, you can write client-side logic directly in your components.

```tsx
// app/components/Counter.tsx
import { h } from "preact";
import { useSignal } from "@preact/signals";

export default function Counter() {
  const count = useSignal(0);
  return <button onClick={() => count.value++}>{count.value}</button>;
}
```

---

## Database (ActiveRecord)

Sage uses ActiveRecord for database interaction.

### Configuration (`config/application.rb`)

```ruby
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "db/development.sqlite3"
)
```

### Models (`app/models/todo.rb`)

```ruby
class Todo < ActiveRecord::Base
end
```

---

## CLI Commands

| Command | Description |
|---------|-------------|
| `sage new <name>` | Create a new Sage project |
| `sage dev` | Start development server with live reload |
| `sage server` | Start production server |
