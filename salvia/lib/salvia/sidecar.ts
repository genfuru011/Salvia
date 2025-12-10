import * as esbuild from "https://deno.land/x/esbuild@v0.19.8/mod.js";
import { denoPlugins } from "jsr:@luca/esbuild-deno-loader@0.9.0";

// port: 0 for dynamic port assignment
const port = 0;

const globalExternals: Record<string, string> = {
  "preact": "globalThis.preact",
  "preact/hooks": "globalThis.preactHooks",
  "preact-render-to-string": "globalThis.renderToString",
  "preact/jsx-runtime": "globalThis.jsxRuntime",
  "react": "globalThis.preact",
  "react-dom": "globalThis.preact",
};

const globalExternalsPlugin = {
  name: "global-externals",
  setup(build: any) {
    const filter = new RegExp(`^(${Object.keys(globalExternals).map(k => k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join("|")})$`);
    build.onResolve({ filter }, (args: any) => {
      return { path: args.path, namespace: "global-externals" };
    });
    build.onLoad({ filter: /.*/, namespace: "global-externals" }, (args: any) => {
      const globalVar = globalExternals[args.path];
      return {
        contents: `module.exports = ${globalVar};`,
        loader: "js"
      };
    });
  },
};

console.log(`🚀 Salvia Sidecar starting...`);

Deno.serve({
  port: port,
  onListen: ({ port }) => {
    console.log(`Listening on http://localhost:${port}/`);
  },
  handler: async (req) => {
    try {
      const { command, params } = await req.json();
      
      if (command === "bundle") {
        const result = await bundle(params.entryPoint, params.externals, params.format, params.globalName, params.configPath);
        return Response.json(result);
      }
      
      if (command === "check") {
         const result = await check(params.entryPoint);
         return Response.json(result);
      }

      if (command === "fmt") {
         const result = await fmt(params.entryPoint);
         return Response.json(result);
      }

      return Response.json({ error: "Unknown command" }, { status: 400 });
    } catch (e) {
      console.error(e);
      return Response.json({ error: e.message }, { status: 500 });
    }
  }
});

async function bundle(entryPoint: string, externals: string[] = [], format: "esm" | "iife" | "cjs" = "esm", globalName?: string, configPath?: string) {
  try {
    const plugins = [...denoPlugins({ configPath: configPath })];
    let actualExternals = externals;

    if (format === "iife") {
      plugins.unshift(globalExternalsPlugin);
      // Remove handled externals from the list
      actualExternals = externals.filter(e => !globalExternals[e]);
    }

    const result = await esbuild.build({
      plugins: plugins,
      entryPoints: [entryPoint],
      bundle: true,
      write: false,
      format: format,
      globalName: globalName || undefined,
      platform: "neutral",
      external: actualExternals,
      jsx: "automatic",
      jsxImportSource: "preact",
    });

    if (result.errors.length > 0) {
        return { error: result.errors[0].text };
    }

    return { code: result.outputFiles[0].text };
  } catch (e) {
    return { error: e.message };
  }
}

async function check(entryPoint: string) {
  try {
    const command = new Deno.Command("deno", {
      args: ["check", entryPoint],
      stdout: "piped",
      stderr: "piped",
    });
    const { code, stdout, stderr } = await command.output();
    const decoder = new TextDecoder();
    
    if (code === 0) {
      return { success: true, message: decoder.decode(stdout) };
    } else {
      return { success: false, message: decoder.decode(stderr) };
    }
  } catch (e) {
    return { success: false, message: e.message };
  }
}

async function fmt(entryPoint: string) {
  try {
    const command = new Deno.Command("deno", {
      args: ["fmt", entryPoint],
      stdout: "piped",
      stderr: "piped",
    });
    const { code, stdout, stderr } = await command.output();
    const decoder = new TextDecoder();
    
    if (code === 0) {
      return { success: true, message: decoder.decode(stdout) };
    } else {
      return { success: false, message: decoder.decode(stderr) };
    }
  } catch (e) {
    return { success: false, message: e.message };
  }
}
