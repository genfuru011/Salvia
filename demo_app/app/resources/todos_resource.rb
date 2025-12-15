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
      ctx.turbo_stream("prepend", "todos-list", "components/TodoItem", todo: todo)
    else
      ctx.status 422
      ctx.text "Title required"
    end
  end

  # Toggle
  post "/:id/toggle" do |ctx, id|
    todo = Todo.find(id)
    todo.update(completed: !todo.completed)
    
    ctx.turbo_stream("replace", "todo_#{todo.id}", "components/TodoItem", todo: todo)
  end

  # Delete
  post "/:id/delete" do |ctx, id|
    todo = Todo.find(id)
    todo.destroy
    
    ctx.turbo_stream("remove", "todo_#{todo.id}")
  end
end
