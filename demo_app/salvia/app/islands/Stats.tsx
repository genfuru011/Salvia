import { h } from "preact";
import { useSignal } from "@preact/signals";
import { useEffect } from "preact/hooks";
// @ts-ignore
import { rpc } from "../client.ts";

export default function Stats() {
  const stats = useSignal({ total: 0, completed: 0 });

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const data = await rpc.todos.stats({});
        stats.value = data;
      } catch (e) {
        console.error(e);
      }
    };
    
    fetchStats();
    const interval = setInterval(fetchStats, 2000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div class="text-sm text-gray-500">
      <span class="font-medium text-gray-900">{stats.value.completed}</span> / {stats.value.total} completed
    </div>
  );
}
