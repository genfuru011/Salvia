#!/usr/bin/env -S deno run --allow-all
// deno-lint-ignore-file
/**
 * Salvia Build Script
 * 
 * Build SSR Islands + Tailwind CSS
 * 
 * Usage:
 *   deno run --allow-all build_ssr.ts
 *   deno run --allow-all build_ssr.ts --watch
 */

import * as esbuild from "https://deno.land/x/esbuild@v0.24.2/mod.js";
import { denoPlugins } from "jsr:@luca/esbuild-deno-loader@0.11";

const WATCH_MODE = Deno.args.includes("--watch");
const VERBOSE = Deno.args.includes("--verbose");

// Resolve deno.json relative to this script
let CONFIG_PATH = new URL("./deno.json", import.meta.url).pathname;

// Check for user config in project root
const USER_CONFIG_PATH = `${Deno.cwd()}/salvia/deno.json`;
try {
  await Deno.stat(USER_CONFIG_PATH);
  CONFIG_PATH = USER_CONFIG_PATH;
} catch {
  // User config not found, use internal one
}

// Load externals from deno.json
let externals = ["preact", "preact/hooks", "preact/jsx-runtime"];
try {
  const configContent = await Deno.readTextFile(CONFIG_PATH);
  const config = JSON.parse(configContent);
  if (config.imports) {
    const importKeys = Object.keys(config.imports);
    externals = [...new Set([...externals, ...importKeys])];
  }
  if (VERBOSE) {
    console.log("📦 Externals loaded from deno.json:", externals);
  }
} catch (e) {
  console.warn("⚠️ Failed to load externals from deno.json:", e);
}

// When running via `deno task --config salvia/deno.json`, CWD is usually the project root.
// But if running from inside salvia/, it's different.
const ROOT_DIR = Deno.cwd().endsWith("/salvia") ? "." : "salvia";
const ISLANDS_DIR = `${ROOT_DIR}/app/islands`;
const PAGES_DIR = `${ROOT_DIR}/app/pages`;
const COMPONENTS_DIR = `${ROOT_DIR}/app/components`;
const SSR_OUTPUT_DIR = `${ROOT_DIR}/server`;
const CLIENT_OUTPUT_DIR = `${ROOT_DIR}/../public/assets/islands`;

// ============================================
// SSR Islands Build
// ============================================

interface IslandFile {
  path: string;
  name: string;
  clientOnly: boolean;
  isPage: boolean;
}

async function findIslandFiles(): Promise<IslandFile[]> {
  const files: IslandFile[] = [];
  
  const scan = async (dir: string, isPage: boolean) => {
    try {
      for await (const entry of Deno.readDir(dir)) {
        if (entry.isFile && (entry.name.endsWith(".tsx") || entry.name.endsWith(".jsx") || entry.name.endsWith(".js"))) {
          if (entry.name.startsWith("_")) continue; // Skip internal files
          const path = `${dir}/${entry.name}`;
          const content = await Deno.readTextFile(path);
          const clientOnly = content.trimStart().startsWith('"client only"') || 
                            content.trimStart().startsWith("'client only'");
          const name = entry.name.replace(/\.(tsx|jsx|js)$/, "");
          files.push({ path, name, clientOnly, isPage });
        }
      }
    } catch {
      // Directory might not exist
    }
  };

  await scan(ISLANDS_DIR, false);
  await scan(PAGES_DIR, true);

  if (files.length === 0) {
    console.log("📁 No components found in app/islands or app/pages.");
  }
  
  return files;
}

async function buildSSR() {
  const islandFiles = await findIslandFiles();
  
  if (islandFiles.length === 0) {
    console.log("⚠️  No Island components found. Skipping SSR build.");
    return;
  }

  const ssrFiles = islandFiles.filter(f => !f.clientOnly);
  const clientFiles = islandFiles.filter(f => !f.isPage);

  if (VERBOSE) {
    console.log("🔍 SSR targets:", ssrFiles.map(f => f.name));
    console.log("🔍 Client targets:", clientFiles.map(f => f.name));
  }

  // Create output directories
  await Deno.mkdir(SSR_OUTPUT_DIR, { recursive: true });
  await Deno.mkdir(CLIENT_OUTPUT_DIR, { recursive: true });

  try {
    // SSR bundle (for QuickJS) - single bundle with all components
    if (ssrFiles.length > 0) {
      // Create a virtual entry point that exports all components
      // Get just the filename from the path
      const entryCode = ssrFiles.map(f => {
        let importPath = f.path;
        // f.path is like "../app/islands/Counter.tsx" or "../app/pages/Home.tsx"
        // We are writing _ssr_entry.js to ISLANDS_DIR ("../app/islands")
        
        if (f.path.startsWith(ISLANDS_DIR)) {
          importPath = `./${f.path.split("/").pop()}`;
        } else if (f.path.startsWith(PAGES_DIR)) {
          // From ../app/islands to ../app/pages is ../pages
          importPath = `../pages/${f.path.split("/").pop()}`;
        }
        return `import ${f.name} from "${importPath}";`;
      }).join("\n") + `
import { h } from "preact";
import renderToString from "preact-render-to-string";

// Salvia SSR Runtime
const components = {
${ssrFiles.map(f => `  "${f.name}": ${f.name}`).join(",\n")}
};

globalThis.SalviaSSR = {
  render: function(name, props) {
    const Component = components[name];
    if (!Component) {
      throw new Error("Component not found: " + name);
    }
    // Handle default export if necessary
    const Comp = Component.default || Component;
    const vnode = h(Comp, props);
    return renderToString(vnode);
  }
};
export default {}; // Ensure it's a module
`;
      const entryPath = `${ISLANDS_DIR}/_ssr_entry.js`;
      await Deno.writeTextFile(entryPath, entryCode);

      await esbuild.build({
        entryPoints: [entryPath],
        bundle: true,
        format: "iife",
        outfile: `${SSR_OUTPUT_DIR}/ssr_bundle.js`,
        platform: "neutral",
        plugins: [...denoPlugins({ configPath: CONFIG_PATH })],
        external: [],
        jsx: "automatic",
        jsxImportSource: "preact",
        banner: {
          js: `// Salvia SSR Bundle - Generated at ${new Date().toISOString()}`,
        },
      });
      
      // Clean up temp file
      await Deno.remove(entryPath);
      
      console.log(`✅ SSR bundle built: ${SSR_OUTPUT_DIR}/ssr_bundle.js (${ssrFiles.map(f => f.name).join(", ")})`);
    }

    // Client bundle (for hydration) - all files
    // We need to wrap each component with a mount function
    const clientEntryPoints = [];
    
    for (const file of clientFiles) {
      const filename = file.path.split("/").pop();
      const wrapperCode = `
import Component from "./${filename}";
import { h, hydrate, render } from "preact";

export function mount(element, props, options) {
  const vnode = h(Component, props);
  if (options && options.hydrate) {
    hydrate(vnode, element);
  } else {
    render(vnode, element);
  }
}
`;
      const wrapperPath = `${ISLANDS_DIR}/_client_${file.name}.js`;
      await Deno.writeTextFile(wrapperPath, wrapperCode);
      clientEntryPoints.push({ in: wrapperPath, out: file.name });
    }

    try {
      const result = await esbuild.build({
        entryPoints: clientEntryPoints,
        bundle: true,
        format: "esm",
        outdir: CLIENT_OUTPUT_DIR,
        platform: "browser",
        plugins: [...denoPlugins({ configPath: CONFIG_PATH })],
        external: externals,
        jsx: "automatic",
        jsxImportSource: "preact",
        minify: true,
        entryNames: "[name]-[hash]",
        metafile: true,
        banner: {
          js: `// Salvia Client Islands - Generated at ${new Date().toISOString()}`,
        },
      });

      // Parse metafile to map original names to hashed filenames
      const outputs = result.metafile?.outputs || {};
      const fileMap: Record<string, string> = {};
      
      for (const [path, _info] of Object.entries(outputs)) {
        // path is like "salvia/../public/assets/islands/Counter-HASH.js"
        // We need to extract "Counter" and the filename "Counter-HASH.js"
        const filename = path.split("/").pop();
        if (!filename) continue;
        
        // Check if this is one of our entry points
        for (const entry of clientEntryPoints) {
          // entry.out is "Counter"
          // filename starts with "Counter-" and ends with ".js"
          if (filename.startsWith(`${entry.out}-`) && filename.endsWith(".js")) {
            fileMap[entry.out] = filename;
            break;
          }
        }
      }

      // Generate manifest (which Islands are client only + file paths)
      const manifest = Object.fromEntries(
        islandFiles.map(f => [
          f.name, 
          { 
            clientOnly: f.clientOnly, 
            serverOnly: f.isPage,
            file: fileMap[f.name] // Add hashed filename if available
          }
        ])
      );
      await Deno.writeTextFile(
        `${SSR_OUTPUT_DIR}/manifest.json`,
        JSON.stringify(manifest, null, 2)
      );
      console.log(`✅ Manifest generated: ${SSR_OUTPUT_DIR}/manifest.json`);

    } finally {
      // Clean up temp files
      for (const entry of clientEntryPoints) {
        try {
          await Deno.remove(entry.in);
        } catch {
          // Ignore if file doesn't exist
        }
      }
    }
    
    console.log(`✅ Client Islands built: ${CLIENT_OUTPUT_DIR}/ (${clientFiles.map(f => f.name).join(", ")})`);

    // Copy islands.js loader
    try {
      const islandsJsPath = new URL("../javascripts/islands.js", import.meta.url).pathname;
      const islandsJsOutput = `${ROOT_DIR}/../public/assets/javascripts/islands.js`;
      await Deno.mkdir(`${ROOT_DIR}/../public/assets/javascripts`, { recursive: true });
      await Deno.copyFile(islandsJsPath, islandsJsOutput);
      console.log(`✅ Loader copied: ${islandsJsOutput}`);
    } catch (e) {
      console.warn("⚠️  Failed to copy islands.js loader:", e);
    }

  } catch (error) {
    const e = error as Error;
    console.error("❌ SSR build error:", e.message || error);
  }
}

// ============================================
// Main Build
// ============================================

async function build() {
  await Promise.all([
    buildSSR(),
  ]);
}

async function watch() {
  console.log("👀 Watching for file changes...");
  
  // Watch Islands source
  const watchDirs = [ISLANDS_DIR, PAGES_DIR, COMPONENTS_DIR, "./app/views"];
  
  for (const dir of watchDirs) {
    (async () => {
      try {
        const watcher = Deno.watchFs(dir);
        let debounceTimer: number | undefined;
        
        for await (const event of watcher) {
          // Ignore generated files
          if (event.paths.some(p => p.includes("_ssr_entry.js") || p.includes("_client_"))) {
            continue;
          }

          if (event.kind === "modify" || event.kind === "create" || event.kind === "remove") {
            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(async () => {
              console.log(`🔄 Changes detected in ${dir}, rebuilding...`);
              await build();
            }, 100);
          }
        }
      } catch {
        // Skip if directory doesn't exist
      }
    })();
  }
  
  // Wait indefinitely
  await new Promise(() => {});
}

// Main execution
console.log("🌿 Salvia Build (SSR + Tailwind)");
console.log("================================");
await build();

if (WATCH_MODE) {
  await watch();
} else {
  await esbuild.stop();
}
