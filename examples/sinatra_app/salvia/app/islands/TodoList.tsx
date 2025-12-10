/** @jsxImportSource preact */
import { h } from "preact";
import { useState } from "preact/hooks";

interface Todo {
  id: number;
  title: string;
  completed: boolean;
}

interface TodoListProps {
  todos: Todo[];
}

export default function TodoList({ todos: initialTodos }: TodoListProps) {
  const [todos, setTodos] = useState<Todo[]>(initialTodos);

  const toggle = (id: number) => {
    setTodos(todos.map(t => t.id === id ? { ...t, completed: !t.completed } : t));
  };

  return (
    <div class="space-y-2">
      <ul class="divide-y divide-gray-200">
        {todos.map(todo => (
          <li 
            key={todo.id} 
            onClick={() => toggle(todo.id)} 
            class={`flex items-center p-4 hover:bg-gray-50 cursor-pointer transition-colors duration-150 ${todo.completed ? "bg-gray-50" : ""}`}
          >
            <div class={`flex-shrink-0 h-6 w-6 rounded-full border-2 flex items-center justify-center mr-4 ${todo.completed ? "border-green-500 bg-green-500" : "border-gray-300"}`}>
              {todo.completed && (
                <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
              )}
            </div>
            <span class={`text-lg ${todo.completed ? "text-gray-400 line-through" : "text-gray-700"}`}>
              {todo.title}
            </span>
          </li>
        ))}
      </ul>
      {todos.length === 0 && (
        <p class="text-center text-gray-500 py-4">No todos yet. Add some!</p>
      )}
    </div>
  );
}
