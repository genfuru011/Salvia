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

// Tailwind CSS (Deno)
import postcss from "npm:postcss@8";
import tailwindcss from "npm:tailwindcss@3";
import autoprefixer from "npm:autoprefixer@10";

const ISLANDS_DIR = "./app/islands";
const SSR_OUTPUT_DIR = "./vendor/server";
const CLIENT_OUTPUT_DIR = "./vendor/client";
const CSS_INPUT = "./app/assets/stylesheets/application.tailwind.css";
const CSS_OUTPUT = "./public/assets/stylesheets/tailwind.css";
const WATCH_MODE = Deno.args.includes("--watch");
const VERBOSE = Deno.args.includes("--verbose");

// ============================================
// Tailwind CSS Build
// ============================================

async function buildCSS() {
  try {
    const css = await Deno.readTextFile(CSS_INPUT);
    
    // Load Tailwind config
    const config = {
      content: [
        "./app/views/**/*.erb",
        "./app/islands/**/*.{js,jsx,tsx}",
        "./public/assets/javascripts/**/*.js"
      ],
      theme: {
        extend: {
          colors: {
            'salvia': {
              50: '#f0f0ff',
              100: '#e4e4ff',
              200: '#cdcdff',
              300: '#a8a8ff',
              400: '#7c7cff',
              500: '#6A5ACD',
              600: '#5a4ab8',
              700: '#4B0082',
              800: '#3d006b',
              900: '#2d0050',
            }
          }
        },
      },
      plugins: [],
    };

    const result = await postcss([
      tailwindcss(config),
      autoprefixer(),
    ]).process(css, { from: CSS_INPUT, to: CSS_OUTPUT });

    await Deno.writeTextFile(CSS_OUTPUT, result.css);
    console.log(`✅ Tailwind CSS built: ${CSS_OUTPUT}`);
  } catch (error) {
    const e = error as Error;
    console.error("❌ CSS build error:", e.message || error);
  }
}

// ============================================
// SSR Islands Build
// ============================================

interface IslandFile {
  path: string;
  name: string;
  clientOnly: boolean;
}

async function findIslandFiles(): Promise<IslandFile[]> {
  const files: IslandFile[] = [];
  try {
    for await (const entry of Deno.readDir(ISLANDS_DIR)) {
      if (entry.isFile && (entry.name.endsWith(".tsx") || entry.name.endsWith(".jsx") || entry.name.endsWith(".js"))) {
        const path = `${ISLANDS_DIR}/${entry.name}`;
        const content = await Deno.readTextFile(path);
        const clientOnly = content.trimStart().startsWith('"client only"') || 
                          content.trimStart().startsWith("'client only'");
        const name = entry.name.replace(/\.(tsx|jsx|js)$/, "");
        files.push({ path, name, clientOnly });
      }
    }
  } catch {
    console.log("📁 app/islands directory not found. Skipping.");
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
  const clientFiles = islandFiles;  // All files go to client

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
        const filename = f.path.split("/").pop();
        return `import ${f.name} from "./${filename}";`;
      }).join("\n") + `
import { h } from "https://esm.sh/preact@10.19.3";
import renderToString from "https://esm.sh/preact-render-to-string@6.3.1?deps=preact@10.19.3";

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
    const vnode = h(Component, props);
    return renderToString(vnode);
  }
};
`;
      const entryPath = `${ISLANDS_DIR}/_ssr_entry.js`;
      await Deno.writeTextFile(entryPath, entryCode);

      await esbuild.build({
        entryPoints: [entryPath],
        bundle: true,
        format: "iife",
        outfile: `${SSR_OUTPUT_DIR}/ssr_bundle.js`,
        platform: "neutral",
        plugins: [...denoPlugins()],
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
    await esbuild.build({
      entryPoints: clientFiles.map(f => f.path),
      bundle: true,
      format: "esm",
      outdir: CLIENT_OUTPUT_DIR,
      platform: "browser",
      plugins: [...denoPlugins()],
      external: [],
      jsx: "automatic",
      jsxImportSource: "preact",
      minify: true,
      banner: {
        js: `// Salvia Client Islands - Generated at ${new Date().toISOString()}`,
      },
    });
    console.log(`✅ Client Islands built: ${CLIENT_OUTPUT_DIR}/ (${clientFiles.map(f => f.name).join(", ")})`);

    // Generate manifest (which Islands are client only)
    const manifest = Object.fromEntries(
      islandFiles.map(f => [f.name, { clientOnly: f.clientOnly }])
    );
    await Deno.writeTextFile(
      `${SSR_OUTPUT_DIR}/manifest.json`,
      JSON.stringify(manifest, null, 2)
    );
    console.log(`✅ Manifest generated: ${SSR_OUTPUT_DIR}/manifest.json`);

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
    buildCSS(),
    buildSSR(),
  ]);
}

async function watch() {
  console.log("👀 Watching for file changes...");
  
  // Watch Islands and CSS source
  const watchDirs = [ISLANDS_DIR, "./app/views", "./app/assets/stylesheets"];
  
  for (const dir of watchDirs) {
    (async () => {
      try {
        const watcher = Deno.watchFs(dir);
        let debounceTimer: number | undefined;
        
        for await (const event of watcher) {
          if (event.kind === "modify" || event.kind === "create") {
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
