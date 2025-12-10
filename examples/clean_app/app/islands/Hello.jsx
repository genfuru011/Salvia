import { h } from 'preact';
import { useState } from 'preact/hooks';

export default function Hello({ name }) {
  const [active, setActive] = useState(false);
  
  console.log("Rendering Hello component for:", name);

  return (
    <div className="max-w-md mx-auto bg-white rounded-xl shadow-md overflow-hidden md:max-w-2xl p-6">
      <div className="uppercase tracking-wide text-sm text-indigo-500 font-semibold">Salvia Island</div>
      <p className="mt-2 text-slate-500">Hello, {name}!</p>
      <button 
        onClick={() => setActive(!active)}
        className={`mt-4 px-4 py-2 rounded ${active ? 'bg-indigo-600 text-white' : 'bg-gray-200 text-gray-800'}`}
      >
        {active ? 'Active!' : 'Click me'}
      </button>
    </div>
  );
}
