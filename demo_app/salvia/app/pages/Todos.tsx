import { h } from "preact";
import Island from "../components/Island.tsx";
import TodoItem from "../components/TodoItem.tsx";
import Stats from "../islands/Stats.tsx";

export default function Todos({ todos }: { todos: any[] }) {
  return (
    <html>
      <head>
        <title>Sage Todo</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script type="module">
          import "@hotwired/turbo";
        </script>
        <script type="module" src="/assets/javascripts/islands.js"></script>
      </head>
      <body class="bg-gray-100 min-h-screen py-10">
        <div class="max-w-2xl mx-auto bg-white rounded-xl shadow-md overflow-hidden">
          <div class="p-8">
            <div class="flex justify-between items-center mb-6">
              <h1 class="text-2xl font-bold text-gray-900">Sage Todo</h1>
              <Island name="Stats" component={Stats} />
            </div>

            <form action="/todos" method="post" class="mb-6 flex gap-2">
              <input type="text" name="title" placeholder="What needs to be done?" 
                     class="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
              <button type="submit" class="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 font-medium">
                Add
              </button>
            </form>

            <div id="todos-list" class="space-y-2">
              {todos.map(todo => <TodoItem todo={todo} />)}
            </div>
          </div>
        </div>
      </body>
    </html>
  );
}
