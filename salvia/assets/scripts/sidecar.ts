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
      
      // If format is IIFE, we need to handle externals by mapping them to globals
      // But esbuild doesn't support this out of the box for IIFE with externals.
      // We can use a plugin to rewrite imports to globals if they are in externals list.
      
      const globalExternalsPlugin = {
        name: 'global-externals',
        setup(build: any) {
          build.onResolve({ filter: /.*/ }, (args: any) => {
            if (externals && externals.includes(args.path)) {
              return { path: args.path, namespace: 'global-externals' };
            }
          });
          
          build.onLoad({ filter: /.*/, namespace: 'global-externals' }, (args: any) => {
            let globalVar = `globalThis['${args.path}']`;
            if (args.path === "preact") globalVar = "globalThis.preact";
            if (args.path === "preact/hooks") globalVar = "globalThis.preactHooks";
            if (args.path === "preact/jsx-runtime") globalVar = "globalThis.jsxRuntime";
            if (args.path === "preact-render-to-string") globalVar = "globalThis.renderToString";
            
            return {
              contents: `module.exports = ${globalVar};`,
              loader: 'js',
            };
          });
        },
      };

      // JIT Bundle for a specific entry point
      const result = await esbuild.build({
        entryPoints: [entryPoint],
        bundle: true,
        format: format || "esm",
        globalName: globalName, // Exports will be in SalviaComponent.default
        platform: "neutral",
        plugins: [
          globalExternalsPlugin,
          ...denoPlugins({ configPath: configPath || `${Deno.cwd()}/salvia/deno.json` })
        ],
        external: [], // We handle externals manually with the plugin
        write: false, // Return in memory
        jsx: "automatic",
        jsxImportSource: "preact",
        minify: false, // Keep it readable for debugging
      });

      const code = result.outputFiles[0].text;
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

const server = Deno.serve({ port: PORT }, handler);
// Output the assigned port so Ruby can read it
console.log(`[Deno Init] Listening on http://localhost:${server.addr.port}/`);

// Handle cleanup on exit
const cleanup = () => {
  console.log("🛑 Stopping Sidecar...");
  esbuild.stop();
  Deno.exit();
};

Deno.addSignalListener("SIGINT", cleanup);
Deno.addSignalListener("SIGTERM", cleanup);
