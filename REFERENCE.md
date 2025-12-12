# Sage Framework Reference Guide

Sage is a modern Ruby web framework designed for simplicity, performance, and seamless integration with modern frontend technologies. It combines the elegance of Ruby with the power of TypeScript and Deno for a superior developer experience.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Project Structure](#project-structure)
3. [Routing & Resources](#routing--resources)
4. [RPC (Remote Procedure Call)](#rpc-remote-procedure-call)
5. [Frontend Integration (Salvia)](#frontend-integration-salvia)
6. [Database (ActiveRecord)](#database-activerecord)
7. [CLI Commands](#cli-commands)
8. [Configuration](#configuration)

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
bundle exec salvia install  # Install frontend dependencies
```

### Starting the Development Server

```bash
bundle exec sage dev
```
This starts the Sage server on port 3000 with live reloading and the Salvia sidecar for TypeScript compilation.

---

## Project Structure

```
my_app/
├── app/
│   ├── models/         # ActiveRecord models
│   ├── resources/      # Sage resources (Controllers)
│   └── pages/          # Salvia pages (TSX)
├── config/
│   ├── application.rb  # App configuration
│   └── routes.rb       # Route definitions
├── db/                 # Database migrations and schema
├── public/             # Static assets
├── salvia/             # Frontend source code
│   ├── app/
│   │   ├── components/ # Shared components
│   │   ├── islands/    # Interactive islands
│   │   └── pages/      # Page components
│   └── deno.json       # Import Map configuration
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
    # Render a Salvia page (TSX)
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
end
```

---

## RPC (Remote Procedure Call)

Sage provides a built-in RPC mechanism to call Ruby methods directly from your TypeScript frontend.

### Defining RPC Methods

In your resource:

```ruby
class TodosResource < Sage::Resource
  # ... standard routes ...

  # Define an RPC method
  rpc :toggle do |id: Integer|
    todo = Todo.find(id)
    todo.update(completed: !todo.completed)
    todo # Return value is sent back as JSON
  end
  
  rpc :stats do
    { total: Todo.count, completed: Todo.where(completed: true).count }
  end
end
```

### Generating the Client

Run the generator to create a type-safe TypeScript client:

```bash
bundle exec sage generate client
```

This creates `salvia/app/client.ts`.

### Using RPC in Frontend

```tsx
import { rpc } from "sage/client";

// Call the RPC method
const result = await rpc.todos.toggle({ id: 1 });
const stats = await rpc.todos.stats({});
```

---

## Frontend Integration (Salvia)

Sage integrates tightly with Salvia for SSR and Island Architecture.

### Pages (`salvia/app/pages/`)

Pages are TSX components rendered on the server.

```tsx
// salvia/app/pages/Home.tsx
import { h } from "preact";

export default function Home({ title }: { title: string }) {
  return (
    <html>
      <head>
        <title>{title}</title>
      </head>
      <body>
        <h1>Hello, {title}!</h1>
      </body>
    </html>
  );
}
```

### Islands (`salvia/app/islands/`)

Islands are interactive components hydrated on the client.

```tsx
// salvia/app/islands/Counter.tsx
import { useSignal } from "@preact/signals";

export default function Counter() {
  const count = useSignal(0);
  return <button onClick={() => count.value++}>{count.value}</button>;
}
```

### Using Islands in Pages

```tsx
import Island from "../components/Island.tsx";
import Counter from "../islands/Counter.tsx";

// In your page
<Island component={Counter} />
```

### Script Helper (`sage/script`)

Inject raw JavaScript without escaping (useful for libraries like Turbo).

```tsx
import Script from "sage/script";

<Script type="module">
  import "@hotwired/turbo";
</Script>
```

### Import Maps (`salvia/deno.json`)

Manage frontend dependencies in `salvia/deno.json`.

```json
{
  "imports": {
    "preact": "https://esm.sh/preact@10.19.6",
    "sage/client": "./app/client.ts",
    "@/": "./app/"
  }
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
| `sage generate client` | Generate RPC client code |
| `salvia install` | Install frontend dependencies |
| `salvia build` | Build frontend for production |

---

## Configuration

### `config/application.rb`

```ruby
require "sage"
require "salvia"

class App < Sage::Base
  # Middleware
  use Rack::Session::Cookie, secret: "secret"
  
  # Mount routes
  mount "/", to: "HomeResource"
end
```

### `config/salvia.rb` (Optional)

Configure Salvia specific settings.

```ruby
Salvia.configure do |config|
  config.root = Dir.pwd
  config.islands_dir = "salvia/app/islands"
end
```
