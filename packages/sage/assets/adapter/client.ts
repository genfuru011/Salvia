import { h, hydrate } from "preact";

function hydrateIslands() {
  const islands = document.querySelectorAll('[data-island]');
  
  islands.forEach(async (island) => {
    const name = island.getAttribute('data-island');
    const propsJson = island.getAttribute('data-props');
    const props = propsJson ? JSON.parse(propsJson) : {};
    
    try {
      // Note: We assume islands are in app/islands/
      // The server maps /assets/app/islands/*.js to the actual file
      const module = await import(`/assets/app/islands/${name}.js`);
      const Component = module.default;
      
      hydrate(h(Component, props), island as Element);
      console.log(`🏝 Hydrated island: ${name}`);
    } catch (e) {
      console.error(`Failed to hydrate island ${name}:`, e);
    }
  });
}

// Run on load and on Turbo navigation
document.addEventListener("DOMContentLoaded", hydrateIslands);
document.addEventListener("turbo:load", hydrateIslands);

console.log("Sage Client initialized");
