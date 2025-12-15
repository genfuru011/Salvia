import { h, hydrate } from "preact";
import { Island } from "sage/island.tsx";

function restoreIslands() {
  const islands = document.querySelectorAll("[data-sage-island]");
  
  islands.forEach(async (root) => {
    const path = root.getAttribute("data-sage-island");
    const props = JSON.parse(root.getAttribute("data-props") || "{}");
    
    try {
      // Dynamic import from the app/ path
      // The path is relative to project root, e.g. "components/Counter.tsx"
      // We need to map it to "/assets/app/components/Counter.tsx"
      // But wait, the import map handles "@/..." -> "/assets/app/..."
      // If path is "components/Counter.tsx", we can try importing "@/components/Counter.tsx"
      
      // However, dynamic import with variable might not work with esbuild unless configured.
      // But here we are in the browser. The browser handles the import.
      // The import map maps "@/..." to "/assets/app/...".
      
      // Let's try importing from the full path if possible, or rely on import map.
      // Since we don't know if the user used "@/..." or not in the path attribute (it comes from server.ts transformation).
      // In server.ts: path: "${relativePath}" -> e.g. "components/Counter.tsx"
      
      const mod = await import(`@/${path}`);
      const Component = mod.default;
      
      hydrate(h(Component, props), root);
    } catch (e) {
      console.error(`Failed to hydrate island: ${path}`, e);
    }
  });
}

// Run hydration when DOM is ready
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", restoreIslands);
} else {
  restoreIslands();
}
