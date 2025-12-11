// Salvia Islands - Client-side Hydration
// Framework-agnostic island loader
// Each island component must export a mount(element, props) function

import "@hotwired/turbo";
import { h, hydrate, render } from "preact";

async function hydrateIsland(island) {
  if (island.dataset.hydrated) return;
  island.dataset.hydrated = "true";

  const name = island.dataset.island;
  const props = JSON.parse(island.dataset.props || '{}');
  const hasSSR = island.innerHTML.trim().length > 0;
  
  try {
    // Use the import map alias which handles dev/prod paths
    const module = await import(`@/islands/${name}.js`);
    
    if (typeof module.mount === 'function') {
      module.mount(island, props, { hydrate: hasSSR });
      console.log(`🏝️ Island ${hasSSR ? 'hydrated' : 'mounted'}: ${name}`);
    } else if (module.default) {
      // Auto-hydration for Preact components
      if (hasSSR) {
        hydrate(h(module.default, props), island);
      } else {
        render(h(module.default, props), island);
      }
      console.log(`🏝️ Island ${hasSSR ? 'hydrated' : 'mounted'} (auto): ${name}`);
    } else {
      console.error(`Island ${name} must export a mount() function or be a Preact component.`);
    }
  } catch (error) {
    console.error(`Failed to load island: ${name}`, error);
    island.removeAttribute('data-hydrated'); // Retry on next pass if failed?
  }
}

async function hydrateAll() {
  const islands = document.querySelectorAll('[data-island]');
  for (const island of islands) {
    hydrateIsland(island);
  }
}

// Initial hydration
document.addEventListener('DOMContentLoaded', hydrateAll);

// Support for Turbo Drive / Turbolinks
document.addEventListener('turbo:load', hydrateAll);
document.addEventListener('turbolinks:load', hydrateAll);

// Expose for manual hydration (e.g. HTMX)
globalThis.Salvia = globalThis.Salvia || {};
globalThis.Salvia.hydrateAll = hydrateAll;
