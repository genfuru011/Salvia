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
         const result = await check(params.entryPoint, params.configPath);
         return Response.json(result);
      }

      if (command === "fmt") {
         const result = await fmt(params.entryPoint, params.configPath);
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
    const externalizePlugin = {
      name: "force-external",
      setup(build: any) {
        if (externals.length === 0) return;
        const filter = new RegExp(`^(${externals.map(k => k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join("|")})$`);
        build.onResolve({ filter }, (args: any) => {
          return { path: args.path, external: true };
        });
      },
    };

    const plugins = [externalizePlugin, ...denoPlugins({ configPath: configPath })];
    let actualExternals = externals;

    if (format === "iife") {
      const globalExternalsPlugin = {
        name: "global-externals",
        setup(build: any) {
          // フレームワーク本体 (preact/react)
          build.onResolve({ filter: /^framework$/ }, (args: any) => {
            return { path: args.path, namespace: "global-external" };
          });
          // Hooks (preact/hooks)
          build.onResolve({ filter: /^framework\/hooks$/ }, (args: any) => {
            return { path: args.path, namespace: "global-external" };
          });
          // JSX Runtime
          build.onResolve({ filter: /^framework\/jsx-runtime$/ }, (args: any) => {
            return { path: args.path, namespace: "global-external" };
          });

          build.onLoad({ filter: /.*/, namespace: "global-external" }, (args: any) => {
            // ここでグローバル変数へのマッピングを行う
            // TODO: React対応時に分岐が必要になる可能性があるが、
            // 現状は Preact 前提で window.Preact にマッピングする。
            // 将来的には deno.json の設定を見て動的に変えることも検討。
            if (args.path === "framework") return { contents: "module.exports = globalThis.Preact;", loader: "js" };
            if (args.path === "framework/hooks") return { contents: "module.exports = globalThis.PreactHooks;", loader: "js" };
            // jsx-runtime は通常グローバルには露出しないが、Preactの場合は本体に含まれることが多い
            // ここでは簡易的に Preact 本体に逃がすか、個別に定義するか。
            // 一旦 Preact 本体と同じ扱いにする。
            if (args.path === "framework/jsx-runtime") return { contents: "module.exports = globalThis.Preact;", loader: "js" };
            return null;
          });
        },
      };
      
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
    // 3. JSX Runtime (Automatic)
    // deno.json の "framework/jsx-runtime" エイリアスを使用
    jsx: "react-jsx",
    jsxImportSource: "framework",
    });

    if (result.errors.length > 0) {
        return { error: result.errors[0].text };
    }

    return { code: result.outputFiles[0].text };
  } catch (e) {
    return { error: e.message };
  }
}

async function check(entryPoint: string, configPath?: string) {
  try {
    const args = ["check"];
    if (configPath) {
      args.push("--config", configPath);
    }
    args.push(entryPoint);

    const command = new Deno.Command("deno", {
      args: args,
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

async function fmt(entryPoint: string, configPath?: string) {
  try {
    const args = ["fmt"];
    if (configPath) {
      args.push("--config", configPath);
    }
    args.push(entryPoint);

    const command = new Deno.Command("deno", {
      args: args,
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
