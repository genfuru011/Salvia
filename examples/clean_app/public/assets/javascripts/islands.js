// Salvia Islands - Client-side Hydration
// Framework-agnostic island loader
// Each island component must export a mount(element, props) function

document.addEventListener('DOMContentLoaded', async () => {
  const islands = document.querySelectorAll('[data-island]');
  
  for (const island of islands) {
    const name = island.dataset.island;
    const props = JSON.parse(island.dataset.props || '{}');
    const hasSSR = island.innerHTML.trim().length > 0;
    
    try {
      const module = await import(`/assets/islands/${name}.js`);
      
      if (typeof module.mount === 'function') {
        module.mount(island, props, { hydrate: hasSSR });
        console.log(`🏝️ Island ${hasSSR ? 'hydrated' : 'mounted'}: ${name}`);
      } else {
        console.error(`Island ${name} must export a mount() function`);
      }
    } catch (error) {
      console.error(`Failed to load island: ${name}`, error);
    }
  }
});
