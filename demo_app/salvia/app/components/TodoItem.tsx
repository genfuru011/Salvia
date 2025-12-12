import { h } from "preact";

// @ts-ignore
declare module "preact" {
  namespace JSX {
    interface IntrinsicElements {
      "turbo-frame": any;
    }
  }
}

export default function TodoItem({ todo }: { todo: any }) {
  return (
    <turbo-frame id={`todo_${todo.id}`}>
      <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg group hover:bg-gray-100 transition-colors mb-2">
        <div class="flex items-center gap-3">
          <form action={`/todos/${todo.id}/toggle`} method="post" class="m-0">
            <button type="submit" class={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-colors ${todo.completed ? 'bg-green-500 border-green-500' : 'border-gray-300 hover:border-blue-500'}`}>
              {todo.completed && (
                <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
              )}
            </button>
          </form>
          <span class={todo.completed ? 'text-gray-400 line-through' : 'text-gray-700'}>
            {todo.title}
          </span>
        </div>
        
        <form action={`/todos/${todo.id}/delete`} method="post" class="m-0 opacity-0 group-hover:opacity-100 transition-opacity">
          <button type="submit" class="text-red-400 hover:text-red-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
          </button>
        </form>
      </div>
    </turbo-frame>
  );
}
