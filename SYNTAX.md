# Sage Syntax Guide

## Routes (`config/routes.rb`)

```ruby
Sage::Router.draw do
  # Root path
  root to: "HomeResource"
  
  # Mount a resource
  mount "/todos", to: "TodosResource"
  
  # Group routes
  group "/api" do
    mount "/users", to: "UsersResource"
  end
end
```

## Resources (`app/resources/*_resource.rb`)

```ruby
class TodosResource < Sage::Resource
  # GET /
  get "/" do |ctx|
    ctx.render "Todos", todos: Todo.all
  end

  # POST /
  post "/" do |ctx|
    Todo.create(title: ctx.params[:title])
    ctx.redirect "/todos"
  end

  # GET /:id
  get "/:id" do |ctx|
    todo = Todo.find(ctx.params[:id])
    ctx.render "Todo", todo: todo
  end
  
  # RPC Method (POST /toggle)
  rpc :toggle, params: { id: Integer } do |ctx, id|
    todo = Todo.find(id)
    todo.update(completed: !todo.completed)
    todo
  end
end
```

## Frontend (`salvia/app/pages/*.tsx`)

```tsx
import { h } from "preact";
import Island from "../components/Island.tsx";
import Counter from "../islands/Counter.tsx";
import Script from "sage/script";

export default function Page({ todos }) {
  return (
    <html>
      <head>
        <title>Todos</title>
        <Script type="module">
          import "@hotwired/turbo";
        </Script>
      </head>
      <body>
        <h1>Todos</h1>
        <ul>
          {todos.map(todo => (
            <li>{todo.title}</li>
          ))}
        </ul>
        <Island component={Counter} />
      </body>
    </html>
  );
}
```
