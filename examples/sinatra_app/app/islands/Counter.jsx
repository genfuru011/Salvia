import { h } from 'preact';
import { useState } from 'preact/hooks';

export default function Counter({ initialCount = 0 }) {
  const [count, setCount] = useState(initialCount);
  return (
    <div className="p-6 max-w-sm mx-auto bg-white rounded-xl shadow-md flex items-center space-x-4">
      <div className="flex-1">
        <p className="text-xl font-medium text-black">Count: {count}</p>
        <p className="text-slate-500">Click to increment</p>
      </div>
      <button 
        onClick={() => setCount(count + 1)}
        className="px-4 py-1 text-sm text-purple-600 font-semibold rounded-full border border-purple-200 hover:text-white hover:bg-purple-600 hover:border-transparent focus:outline-none focus:ring-2 focus:ring-purple-600 focus:ring-offset-2"
      >
        Increment
      </button>
    </div>
  );
}
