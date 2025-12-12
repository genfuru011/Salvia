import * as esbuild from "https://deno.land/x/esbuild@v0.24.2/mod.js";
import { denoPlugins } from "jsr:@luca/esbuild-deno-loader@0.11";

// Use port 0 to let OS assign a free port
const PORT = 0;

console.log(`[Deno Init] 🚀 Salvia Sidecar starting...`);

const handler = async (request: Request): Promise<Response> => {
  if (request.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  try {
    const body = await request.json();
    const { command, params } = body;

    if (command === "bundle") {
      const { entryPoint, externals, format, globalName, configPath } = params;
      
      // Load globals from deno.json
      const defaultGlobals: Record<string, string> = {
        "preact": "globalThis.Preact",
        "preact/hooks": "globalThis.PreactHooks",
        "@preact/signals": "globalThis.PreactSignals",
        "preact/jsx-runtime": "globalThis.PreactJsxRuntime",
      };

      let userGlobals: Record<string, string> = {};
      try {
        const cfgPath = configPath || `${Deno.cwd()}/salvia/deno.json`;
        const configText = await Deno.readTextFile(cfgPath);
        const config = JSON.parse(configText);
        if (config.salvia && config.salvia.globals) {
          userGlobals = config.salvia.globals;
        }
      } catch {
        // Ignore if config not found or invalid
      }

      const allGlobals = { ...defaultGlobals, ...userGlobals };
      
      // If format is IIFE, we need to handle externals by mapping them to globals
      // But esbuild doesn't support this out of the box for IIFE with externals.
      // We can use a plugin to rewrite imports to globals if they are in externals list.
      
        // 4. Global Externals (for IIFE format)
        const globalExternalsPlugin = {
            name: "global-externals",
            setup(build: any) {
              // Register resolvers for all globals
              for (const pkg of Object.keys(allGlobals)) {
                // Escape regex special characters
                const escapedPkg = pkg.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                const filter = new RegExp(`^${escapedPkg}$`);
                
                build.onResolve({ filter }, (args: any) => {
                  return { path: args.path, namespace: "global-external" };
                });
              }

              build.onLoad({ filter: /.*/, namespace: "global-external" }, (args: any) => {
                const globalVar = allGlobals[args.path];
                if (globalVar) {
                  // Use module.exports to support both default and named imports via esbuild's CommonJS interop.
                  // This requires a minimal CommonJS shim (module.exports) in the execution environment (vendor_setup.ts).
                  return { contents: `module.exports = ${globalVar};`, loader: "js" };
                }
                return null;
              });
            },
        };

      const externalizePlugin = {
        name: 'externalize-deps',
        setup(build: any) {
          build.onResolve({ filter: /.*/ }, (args: any) => {
            if (externals && externals.includes(args.path)) {
              return { path: args.path, external: true };
            }
          });
        },
      };

      const isIIFE = format === "iife";
      
      const plugins = [
        ...denoPlugins({ configPath: configPath || `${Deno.cwd()}/salvia/deno.json` })
      ];
      
      if (isIIFE && !entryPoint.endsWith("vendor_setup.ts")) {
        // IIFEの場合は、globalExternalsPlugin を使う
        // ただし、denoPlugins よりも前に配置して、framework などの解決を横取りする
        plugins.unshift(globalExternalsPlugin);
      } else {
        plugins.unshift(externalizePlugin);
      }

      // JIT Bundle for a specific entry point
      const result = await esbuild.build({
        entryPoints: [entryPoint],
        bundle: true,
        format: format || "esm",
        globalName: globalName || undefined, // Exports will be in SalviaComponent.default
        platform: "neutral",
        plugins: plugins,
        external: [], // We handle externals manually with plugins
        write: false, // Return in memory
    // 3. JSX Runtime (Automatic)
    // deno.json の "preact/jsx-runtime" エイリアスを使用
    jsx: "automatic",
    jsxImportSource: "preact",
        minify: false, // Keep it readable for debugging
      });

      const code = result.outputFiles[0].text;
      // Deno.writeTextFileSync("debug_bundle.js", code);

      return new Response(JSON.stringify({ code }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    if (command === "check") {
      const { entryPoint, configPath } = params;
      const cmd = new Deno.Command("deno", {
        args: ["check", "--config", configPath || "deno.json", entryPoint],
        stdout: "piped",
        stderr: "piped",
        cwd: Deno.cwd(),
      });
      
      const output = await cmd.output();
      const success = output.code === 0;
      const message = new TextDecoder().decode(output.stderr);
      
      return new Response(JSON.stringify({ success, message }), {
        headers: { "Content-Type": "application/json" },
      });
    }
    
    if (command === "fmt") {
      const { entryPoint, configPath } = params;
      const cmd = new Deno.Command("deno", {
        args: ["fmt", "--config", configPath || "deno.json", entryPoint],
        stdout: "piped",
        stderr: "piped",
        cwd: Deno.cwd(),
      });
      
      const output = await cmd.output();
      const success = output.code === 0;
      const message = new TextDecoder().decode(output.stderr);
      
      return new Response(JSON.stringify({ success, message }), {
        headers: { "Content-Type": "application/json" },
      });
    }
    
    if (command === "ping") {
        return new Response(JSON.stringify({ status: "pong" }));
    }

    return new Response("Unknown command", { status: 400 });

  } catch (e) {
    const err = e as Error;
    console.error("Sidecar Error:", err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
};

const server = Deno.serve({ 
  port: PORT,
  onListen: ({ port, hostname }) => {
    // Output JSON handshake for reliable parsing
    const msg = JSON.stringify({ port, status: "ready" });
    console.log(msg);
    console.log(`[Deno Init] Listening on http://${hostname}:${port}/`);
  }
}, handler);

// Handle cleanup on exit
const cleanup = () => {
  console.log("🛑 Stopping Sidecar...");
  esbuild.stop();
  Deno.exit();
};

Deno.addSignalListener("SIGINT", cleanup);
Deno.addSignalListener("SIGTERM", cleanup);
