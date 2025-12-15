import { renderToString } from "npm:preact-render-to-string@6.3.1";
import { h } from "npm:preact@10.19.6";
import * as esbuild from "https://deno.land/x/esbuild@v0.20.1/mod.js";
import { denoPlugins } from "https://deno.land/x/esbuild_deno_loader@0.9.0/mod.ts";
import { join, resolve } from "https://deno.land/std@0.213.0/path/mod.ts";

const SOCKET_PATH = Deno.env.get("SOCKET_PATH") || "tmp/sockets/sage_deno.sock";
const PROJECT_ROOT = Deno.cwd();

async function handleRpc(command: string, params: any) {
  if (command === "render_page") {
    const { page, props } = params;
    try {
      // Dynamic import using the import map defined in deno.json
      // Add cache buster for dev mode
      // We need to resolve the path relative to the project root
      const pagePath = `file://${join(PROJECT_ROOT, "app", "pages", `${page}.tsx`)}?t=${Date.now()}`;
      const mod = await import(pagePath);
      const Page = mod.default;

      const body = renderToString(h(Page, props));

      // Read import map to inject into HTML
      const denoJson = JSON.parse(await Deno.readTextFile(join(PROJECT_ROOT, "deno.json")));
      
      // Transform npm: imports to esm.sh for browser
      const browserImports: Record<string, string> = {};
      for (const [key, value] of Object.entries(denoJson.imports)) {
        if (typeof value === "string") {
          if (value.startsWith("npm:")) {
            browserImports[key] = `https://esm.sh/${value.slice(4)}`;
          } else if (key !== "esbuild" && key !== "preact-render-to-string") {
            browserImports[key] = value;
          }
        }
      }
      const importMap = JSON.stringify({ imports: browserImports });

      // HMR Script (only in dev)
      const hmrScript = `
        <script>
          (() => {
            const es = new EventSource("/_sage/reload");
            es.onmessage = () => {
              console.log("🌿 Sage HMR: Reloading...");
              location.reload();
            };
          })();
        </script>
      `;

      const html = `<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="importmap">
      ${importMap}
    </script>
    <script type="module">
      import * as Turbo from "@hotwired/turbo";
      // Ensure Turbo is started
      if (!window.Turbo) {
        window.Turbo = Turbo;
      }
    </script>
    <script type="module" src="/assets/sage/client.js"></script>
    ${hmrScript}
  </head>
  <body>
    ${body}
  </body>
</html>`;

      return new Response(html, {
        headers: { "Content-Type": "text/html" },
      });
    } catch (e) {
      console.error(`Error rendering page ${page}:`, e);
      return new Response(`
        <html>
          <head><title>Rendering Error</title></head>
          <body>
            <h1>Error rendering ${page}</h1>
            <pre>${e instanceof Error ? e.stack : String(e)}</pre>
          </body>
        </html>
      `, {
        status: 500,
        headers: { "Content-Type": "text/html" },
      });
    }
  }

  if (command === "render_component") {
    const { path, props } = params;
    try {
      // Dynamic import
      // Note: path should be relative to app/ e.g. "components/TodoItem"
      const importPath = `file://${join(PROJECT_ROOT, "app", `${path}.tsx`)}?t=${Date.now()}`;
      console.log(`Loading component: ${importPath}`);
      const mod = await import(importPath);
      const Component = mod.default;
      
      const html = renderToString(h(Component, props));
      
      return new Response(html, {
        headers: { "Content-Type": "text/html" },
      });
    } catch (e) {
      console.error(`Error rendering component ${path}:`, e);
      return new Response(`<!-- Error rendering ${path}: ${e} -->`, {
        status: 500,
        headers: { "Content-Type": "text/html" },
      });
    }
  }

  return new Response("Unknown RPC command", { status: 400 });
}

async function handleAsset(path: string) {
  // /assets/app/components/TodoItem.js -> app/components/TodoItem.tsx
  const relativePath = path.replace("/assets/", "");
  
  // Special case for sage/client.js which might be in a different location or virtual
  // For now, let's assume it maps to adapter/client.ts if requested as sage/client.js
  let sourcePath;
  if (relativePath === "sage/client.js") {
    // Use import.meta.url to resolve relative to server.ts (which is in adapter/)
    // We need to point to client.ts in the same directory as server.ts
    sourcePath = new URL("./client.ts", import.meta.url).pathname;
  } else {
    // Resolve absolute path for esbuild
    // relativePath includes "app/...", so we join with PROJECT_ROOT's parent? No, relativePath is "app/components/..."
    // Wait, path is "/assets/app/components/TodoItem.js"
    // relativePath is "app/components/TodoItem.js"
    // We want "PROJECT_ROOT/app/components/TodoItem.tsx"
    sourcePath = join(PROJECT_ROOT, relativePath.replace(/\.js$/, ".tsx"));
  }
  
  console.log(`Building asset: ${path} -> ${sourcePath}`);

  // Read deno.json to get external dependencies and compiler options
  const denoJson = JSON.parse(await Deno.readTextFile(join(PROJECT_ROOT, "deno.json")));
  // Exclude local aliases like "@/" from externals, we want to bundle those
  const external = Object.keys(denoJson.imports).filter(k => !k.startsWith("@/"));
  const compilerOptions = denoJson.compilerOptions || {};

  try {
    const result = await esbuild.build({
      plugins: [...denoPlugins({ configPath: join(PROJECT_ROOT, "deno.json") })],
      entryPoints: [sourcePath],
      write: false,
      bundle: true,
      format: "esm",
      target: "es2022",
      external: external, // Use dynamic externals from deno.json
      jsx: compilerOptions.jsx === "react-jsx" ? "automatic" : "transform",
      jsxImportSource: compilerOptions.jsxImportSource,
      jsxFactory: compilerOptions.jsxFactory,
      jsxFragment: compilerOptions.jsxFragmentFactory,
    });

    const code = result.outputFiles[0].text;

    return new Response(code, {
      headers: { "Content-Type": "application/javascript" },
    });
  } catch (e) {
    console.error("Build error:", e);
    return new Response(`console.error("Build failed: ${e.message}")`, {
      status: 500,
      headers: { "Content-Type": "application/javascript" },
    });
  }
}

if (import.meta.main) {
  console.log(`🦕 Deno Adapter listening on ${SOCKET_PATH}`);

  // Watch for changes in app directory
  (async () => {
    const watcher = Deno.watchFs(join(PROJECT_ROOT, "app"));
    let timeout = null;
    for await (const event of watcher) {
      if (event.kind === "modify" || event.kind === "create" || event.kind === "remove") {
        // Debounce
        if (timeout) clearTimeout(timeout);
        timeout = setTimeout(async () => {
          console.log("♻️  File changed, notifying Sage...");
          try {
            await fetch("http://localhost:3000/_sage/notify", { method: "POST" });
          } catch (e) {
            // Ignore connection errors (Sage might be restarting)
          }
        }, 100);
      }
    }
  })();
  
  Deno.serve({ path: SOCKET_PATH }, async (req) => {
    const url = new URL(req.url);

    if (url.pathname.startsWith("/rpc/")) {
      const command = url.pathname.replace("/rpc/", "");
      try {
        const params = await req.json();
        return await handleRpc(command, params);
      } catch (e) {
        return new Response("Invalid JSON", { status: 400 });
      }
    }

    if (url.pathname.startsWith("/assets/")) {
      return await handleAsset(url.pathname);
    }

    return new Response("Not Found", { status: 404 });
  });
}
