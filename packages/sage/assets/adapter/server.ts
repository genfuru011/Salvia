// v2.2 - Sage Native Adapter (Deno) with Virtual Modules & Robust Hydration
import { renderToString } from "preact-render-to-string";
import { h } from "preact";
import * as esbuild from "https://deno.land/x/esbuild@v0.20.1/mod.js";
import { denoPlugins } from "https://deno.land/x/esbuild_deno_loader@0.9.0/mod.ts";

const SOCKET_PATH = Deno.env.get("SALVIA_SOCKET_PATH");
const PROJECT_ROOT = Deno.env.get("SALVIA_PROJECT_ROOT") || Deno.cwd();
const ADAPTER_ROOT = new URL(".", import.meta.url).pathname;

// Import Map for client-side
const importMap = {
  imports: {
    "preact": "https://esm.sh/preact@10.19.6",
    "preact/jsx-runtime": "https://esm.sh/preact@10.19.6/jsx-runtime",
    "preact/hooks": "https://esm.sh/preact@10.19.6/hooks",
    "@/": "/assets/app/",
    "sage/": "/assets/sage/"
  }
};

// Virtual Module Content for sage/island.tsx
const SAGE_ISLAND_CONTENT = `
import { h } from "preact";

export function Island({ path, props, children }) {
  return (
    <div
      data-sage-island={path}
      data-props={JSON.stringify(props)}
      style={{ display: "contents" }}
    >
      {children}
    </div>
  );
}
`;

// Esbuild Plugin for Sage (Hydration & Virtual Modules)
const sagePlugin = {
  name: 'sage-plugin',
  setup(build: any) {
    // 1. Resolve Virtual Modules
    build.onResolve({ filter: /^sage\/island\.tsx$/ }, (args: any) => ({
      path: args.path,
      namespace: 'sage-virtual',
    }));

    build.onLoad({ filter: /.*/, namespace: 'sage-virtual' }, (args: any) => {
      if (args.path === "sage/island.tsx") {
        return { contents: SAGE_ISLAND_CONTENT, loader: 'tsx' };
      }
    });

    // 2. Transform "use hydration" components
    build.onLoad({ filter: /\.tsx$/ }, async (args: any) => {
      const text = await Deno.readTextFile(args.path);
      if (!text.includes('"use hydration"') && !text.includes("'use hydration'")) {
        return null;
      }

      const relativePath = args.path.replace(PROJECT_ROOT + '/app/', '');
      
      // Remove directive
      let newText = text.replace(/["']use hydration["'];?/, "");
      let componentName = "$$IslandComp";

      // Handle export default
      if (newText.match(/export\s+default\s+function\s+\w+/)) {
         const match = newText.match(/export\s+default\s+function\s+(\w+)/);
         if (match) {
           componentName = match[1];
           newText = newText.replace(/export\s+default\s+function/, "function");
         }
      } else if (newText.match(/export\s+default\s+class\s+\w+/)) {
         const match = newText.match(/export\s+default\s+class\s+(\w+)/);
         if (match) {
           componentName = match[1];
           newText = newText.replace(/export\s+default\s+class/, "class");
         }
      } else {
         // export default expression
         newText = newText.replace(/export\s+default/, `const ${componentName} =`);
      }

      // Append wrapper
      newText += `
        import { h } from "preact";
        import { Island } from "sage/island.tsx";
        
        export default function(props) {
          return h(Island, { path: "${relativePath}", props: props }, h(${componentName}, props));
        }
      `;

      return { contents: newText, loader: 'tsx' };
    });
  },
};

async function buildPage(pagePath: string) {
  const result = await esbuild.build({
    entryPoints: [pagePath],
    bundle: true,
    write: false,
    format: 'esm',
    platform: 'neutral',
    plugins: [
      sagePlugin,
      ...denoPlugins({ configPath: `${PROJECT_ROOT}/deno.json` })
    ],
    external: ['preact', 'preact-render-to-string', 'preact/hooks'],
    jsx: 'automatic',
    jsxImportSource: 'preact'
  });

  return result.outputFiles[0].text;
}

async function handleRpc(req: Request) {
  const url = new URL(req.url);
  const command = url.pathname.replace("/rpc/", "");
  const params = await req.json();
  console.log("RPC params:", params);

  if (command === "render_page") {
    try {
      const pagePath = `${PROJECT_ROOT}/app/pages/${params.page}.tsx`;
      
      // Build the page with hydration transformation
      const code = await buildPage(pagePath);
      
      // Import the bundled code via data URI
      const mod = await import(`data:text/javascript;base64,${btoa(code)}`);
      const Page = mod.default;
      
      const body = renderToString(h(Page, params.props));
      
      return new Response(`
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <title>Sage App</title>
            <script src="https://cdn.tailwindcss.com"></script>
            <script type="importmap">${JSON.stringify(importMap)}</script>
            <script type="module" src="/assets/sage/client.js"></script>
            <script type="module" src="https://esm.sh/@hotwired/turbo@8.0.4"></script>
          </head>
          <body>
            ${body}
          </body>
        </html>
      `, { headers: { "Content-Type": "text/html" } });
    } catch (e) {
      console.error(e);
      return new Response(`Error rendering page ${params.path}: ${e}`, { status: 500 });
    }
  }
  
  if (command === "render_component") {
    try {
      const mod = await import(`${PROJECT_ROOT}/app/${params.path}.tsx`);
      const Component = mod.default;
      const body = renderToString(h(Component, params.props));
      return new Response(body, { headers: { "Content-Type": "text/html" } });
    } catch (e) {
      console.error(e);
      return new Response(`Error rendering component ${params.path}: ${e}`, { status: 500 });
    }
  }

  return new Response("Unknown RPC command", { status: 400 });
}

async function handleAsset(req: Request) {
  const url = new URL(req.url);
  let path = url.pathname.replace("/assets/", "");
  
  // Map sage/ assets to adapter directory
  let filePath;
  if (path.startsWith("sage/")) {
    // Remove "sage/" prefix to map to adapter root
    const relativePath = path.replace(/^sage\//, "");
    filePath = `${ADAPTER_ROOT}${relativePath}`;
  } else {
    // Handle app/ prefix if present (from import map)
    if (path.startsWith("app/")) {
      filePath = `${PROJECT_ROOT}/${path}`;
    } else {
      filePath = `${PROJECT_ROOT}/app/${path}`;
    }
  }

  console.log(`[Asset] Request: ${path}, Resolved: ${filePath}`);

  try {
    // Check if file exists, handling extension replacement
    let finalPath = filePath;
    try {
      await Deno.stat(finalPath);
    } catch {
      // Try public/assets/ if not found in app/
      if (!path.startsWith("sage/") && !path.startsWith("app/")) {
        const publicPath = `${PROJECT_ROOT}/public/assets/${path}`;
        try {
          await Deno.stat(publicPath);
          finalPath = publicPath;
        } catch {
          // Continue to extension checks
        }
      }

      // Try .ts
      if (finalPath.endsWith(".js")) {
        const tsPath = finalPath.replace(/\.js$/, ".ts");
        try {
          await Deno.stat(tsPath);
          finalPath = tsPath;
        } catch {
           // Try .tsx
           const tsxPath = finalPath.replace(/\.js$/, ".tsx");
           try {
             await Deno.stat(tsxPath);
             finalPath = tsxPath;
           } catch {
             throw new Error("File not found");
           }
        }
      } else {
        throw new Error("File not found");
      }
    }
    
    // Build with esbuild for browser
    const result = await esbuild.build({
      entryPoints: [finalPath],
      bundle: true,
      write: false,
      format: 'esm',
      platform: 'browser',
      plugins: [
        sagePlugin, // Use sagePlugin here too for virtual modules
        ...denoPlugins({ configPath: `${PROJECT_ROOT}/deno.json` })
      ],
      external: ['preact', 'preact/hooks', 'preact/jsx-runtime', '@/sage/*', '@/*'], // Externalize dependencies
      jsx: 'automatic',
      jsxImportSource: 'preact'
    });

    return new Response(result.outputFiles[0].text, {
      headers: { "Content-Type": "application/javascript" }
    });
  } catch (e) {
    console.error(`Asset error for ${path}:`, e);
    return new Response("Not Found", { status: 404 });
  }
}

if (SOCKET_PATH) {
  console.log(`🦕 Deno Adapter listening on ${SOCKET_PATH}`);
  Deno.serve({ path: SOCKET_PATH }, async (req) => {
    const url = new URL(req.url);
    if (url.pathname.startsWith("/rpc/")) {
      return handleRpc(req);
    } else if (url.pathname.startsWith("/assets/")) {
      return handleAsset(req);
    }
    return new Response("Not Found", { status: 404 });
  });
} else {
  console.error("SALVIA_SOCKET_PATH not set");
  Deno.exit(1);
}
