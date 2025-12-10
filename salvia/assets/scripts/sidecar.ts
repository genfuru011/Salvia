import * as esbuild from "https://deno.land/x/esbuild@v0.24.2/mod.js";
import { denoPlugins } from "jsr:@luca/esbuild-deno-loader@0.11";

const SOCKET_PATH = Deno.args[0] || "/tmp/salvia.sock";

// Ensure socket file is removed before starting
try {
  await Deno.remove(SOCKET_PATH);
} catch {
  // Ignore
}

console.log(`🚀 Salvia Sidecar starting on ${SOCKET_PATH}...`);

const handler = async (request: Request): Promise<Response> => {
  if (request.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  try {
    const body = await request.json();
    const { command, params } = body;

    if (command === "bundle") {
      const { entryPoint, externals } = params;
      
      // JIT Bundle for a specific entry point
      const result = await esbuild.build({
        entryPoints: [entryPoint],
        bundle: true,
        format: "iife",
        globalName: "SalviaComponent", // Exports will be in SalviaComponent.default
        platform: "neutral",
        plugins: [...denoPlugins({ configPath: `${Deno.cwd()}/deno.json` })],
        external: externals || [],
        write: false, // Return in memory
        jsx: "automatic",
        jsxImportSource: "preact",
        minify: false, // Keep it readable for debugging, maybe add option later
      });

      const code = result.outputFiles[0].text;
      return new Response(JSON.stringify({ code }), {
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

Deno.serve({ path: SOCKET_PATH }, handler);

// Handle cleanup on exit
const cleanup = () => {
  console.log("🛑 Stopping Sidecar...");
  try {
    Deno.removeSync(SOCKET_PATH);
  } catch {}
  esbuild.stop();
  Deno.exit();
};

Deno.addSignalListener("SIGINT", cleanup);
Deno.addSignalListener("SIGTERM", cleanup);
