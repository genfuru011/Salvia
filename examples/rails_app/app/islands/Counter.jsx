import { h } from 'preact';
import { useState } from 'preact/hooks';

export default function Counter({ initialCount = 0 }) {
  const [count, setCount] = useState(initialCount);
  
  console.log("Rendering Rails Counter with:", count);

  return (
    <div className="p-6 max-w-sm mx-auto bg-white rounded-xl shadow-lg flex items-center space-x-4">
      <div className="shrink-0">
        <div className="h-12 w-12 bg-indigo-500 rounded-full flex items-center justify-center text-white font-bold text-xl">
          {count}
        </div>
      </div>
      <div>
        <div className="text-xl font-medium text-black">Rails Counter</div>
        <p className="text-slate-500">Click to increment!</p>
        <button 
          onClick={() => setCount(count + 1)}
          className="mt-2 px-4 py-1 text-sm text-indigo-600 font-semibold rounded-full border border-indigo-200 hover:text-white hover:bg-indigo-600 hover:border-transparent focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2"
        >
          Increment
        </button>
      </div>
    </div>
  );
}
