/** @jsxImportSource preact */
import { h } from "preact";
import Island from "../../components/Island.tsx";
import TodoList from "../../islands/TodoList.tsx";

interface Todo {
  id: number;
  title: string;
  completed: boolean;
}

interface TodosIndexProps {
  todos: Todo[];
}

export default function TodosIndex({ todos }: TodosIndexProps) {
  return (
    <html>
      <head>
        <title>Todos</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script type="module" src="/assets/javascripts/islands.js"></script>
      </head>
      <body class="bg-gray-100 min-h-screen py-10">
        <div class="max-w-2xl mx-auto bg-white shadow-lg rounded-lg overflow-hidden">
          <div class="bg-indigo-600 px-6 py-4">
            <h1 class="text-2xl font-bold text-white">Todo List</h1>
          </div>
          <div class="p-6">
            <Island name="TodoList" component={TodoList} props={{ todos }} />
          </div>
        </div>
      </body>
    </html>
  );
}
