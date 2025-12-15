import { useSignal } from "@preact/signals";

export default function Counter() {
  const count = useSignal(0);
  return (
    <div class="p-4 border rounded bg-gray-50">
      <p class="text-lg mb-2 font-semibold">Count: {count}</p>
      <button 
        onClick={() => count.value++} 
        class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded transition-colors"
      >
        Increment
      </button>
    </div>
  );
}
