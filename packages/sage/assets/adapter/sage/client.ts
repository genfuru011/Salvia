import { hydrate as preactHydrate, h } from "preact";

export async function rpc<T = any>(resource: string, action: string, params: Record<string, any> = {}): Promise<T> {
  const response = await fetch(`/${resource}/${action}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify(params),
  });

  if (!response.ok) {
    throw new Error(`RPC call failed: ${response.status} ${response.statusText}`);
  }

  return response.json();
}

async function hydrateIslands() {
  const islands = document.querySelectorAll('[data-sage-island]');
  console.log(`Found ${islands.length} islands to hydrate`);
  
  for (const island of islands) {
    const path = island.getAttribute('data-sage-island');
    const propsStr = island.getAttribute('data-props');
    const props = propsStr ? JSON.parse(propsStr) : {};

    if (!path) continue;

    try {
      console.log(`Hydrating island: ${path}`);
      // Dynamic import using the import map alias
      const mod = await import(`@/${path}`);
      const Component = mod.default;
      
      if (!Component) {
        throw new Error(`Default export not found in ${path}`);
      }

      preactHydrate(h(Component, props), island);
      console.log(`🏝 Hydrated island: ${path}`);
    } catch (e) {
      console.error(`Failed to hydrate island: ${path}`, e);
    }
  }
}

// Run hydration
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', hydrateIslands);
} else {
  hydrateIslands();
}

console.log("Sage Client initialized");