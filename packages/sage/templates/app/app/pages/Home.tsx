import Counter from "../islands/Counter.tsx";
import Island from "../components/Island.tsx";

export default function Home() {
  return (
    <div class="min-h-screen bg-gray-100 flex flex-col items-center justify-center">
      <div class="bg-white p-8 rounded-xl shadow-md max-w-md w-full text-center">
        <h1 class="text-3xl font-bold text-gray-900 mb-4">Welcome to Sage</h1>
        <p class="text-gray-600 mb-6">You're running a Sage application with Deno Sidecar.</p>
        <div class="flex justify-center">
          <Island name="Counter">
            <Counter />
          </Island>
        </div>
      </div>
    </div>
  );
}
