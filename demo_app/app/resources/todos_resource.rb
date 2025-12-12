class TodosResource < Sage::Resource
  # RPC for Stats Island
  rpc :stats do |ctx|
    {
      total: Todo.count,
      completed: Todo.where(completed: true).count
    }
  end

  # Standard Routes
  get "/" do |ctx|
    todos = Todo.order(created_at: :desc)
    ctx.render "Todos", todos: todos
  end

  post "/" do |ctx|
    title = ctx.req.params["title"]
    
    if title && !title.empty?
      todo = Todo.create(title: title)
      
      # Return Turbo Stream using Salvia Component
      html = ctx.salvia_component("components/TodoItem", todo: todo)
      stream = <<~HTML
        <turbo-stream action="prepend" target="todos-list">
          <template>#{html}</template>
        </turbo-stream>
      HTML
      
      ctx.res.headers["Content-Type"] = "text/vnd.turbo-stream.html"
      ctx.body stream
    else
      ctx.status 422
      ctx.text "Title required"
    end
  end

  # Toggle
  post "/:id/toggle" do |ctx, id|
    todo = Todo.find(id)
    todo.update(completed: !todo.completed)
    
    html = ctx.salvia_component("components/TodoItem", todo: todo)
    stream = <<~HTML
      <turbo-stream action="replace" target="todo_#{todo.id}">
        <template>#{html}</template>
      </turbo-stream>
    HTML
    
    ctx.res.headers["Content-Type"] = "text/vnd.turbo-stream.html"
    ctx.body stream
  end

  # Delete
  post "/:id/delete" do |ctx, id|
    todo = Todo.find(id)
    todo.destroy
    
    stream = <<~HTML
      <turbo-stream action="remove" target="todo_#{todo.id}"></turbo-stream>
    HTML
    
    ctx.res.headers["Content-Type"] = "text/vnd.turbo-stream.html"
    ctx.body stream
  end
end
