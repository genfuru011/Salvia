class TodosController < ApplicationController
  def index
    @todos = Todo.order(created_at: :desc)
    @todo = Todo.new
  end

  def create
    @todo = Todo.new(todo_params)
    if @todo.save
      if htmx_request?
        render partial: "todos/todo", locals: { todo: @todo }
      else
        redirect_to "/todos"
      end
    else
      # エラーハンドリング（簡易）
      render plain: "Error", status: 422
    end
  end

  def update
    @todo = Todo.find(params[:id])
    if @todo.update(completed: !@todo.completed)
      if htmx_request?
        render partial: "todos/todo", locals: { todo: @todo }
      else
        redirect_to "/todos"
      end
    else
      render plain: "Error", status: 422
    end
  end

  def destroy
    @todo = Todo.find(params[:id])
    @todo.destroy
    if htmx_request?
      render plain: "" # 要素を削除
    else
      redirect_to "/todos"
    end
  end

  private

  def todo_params
    { title: params["title"] }
  end
end
