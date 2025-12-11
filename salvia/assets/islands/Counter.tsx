import { h } from "preact";
import { useState } from "preact/hooks";

export default function Counter() {
  const [count, setCount] = useState(0);
  return (
    <div class="p-4 border rounded-lg">
      <p class="text-lg mb-2">Count: {count}</p>
      <button 
        onClick={() => setCount(count + 1)}
        class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
      >
        Increment
      </button>
    </div>
  );
}
