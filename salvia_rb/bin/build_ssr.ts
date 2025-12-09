#!/usr/bin/env -S deno run --allow-read --allow-write --allow-net --allow-env --allow-run
/**
 * Salvia SSR Build Script
 * 
 * TSX/JSX Islands をバンドルして QuickJS で実行可能な JS に変換します。
 * 
 * Usage:
 *   deno run --allow-all bin/build_ssr.ts
 *   deno run --allow-all bin/build_ssr.ts --watch
 */

import * as esbuild from "https://deno.land/x/esbuild@v0.20.0/mod.js";
import { denoPlugins } from "jsr:@luca/esbuild-deno-loader@0.10";
import { walk } from "jsr:@std/fs@0.229/walk";
import { parse } from "jsr:@std/flags@0.224";

// CLI 引数解析
const args = parse(Deno.args, {
  boolean: ["watch", "verbose"],
  string: ["outfile", "islands-dir"],
  default: {
    watch: false,
    verbose: false,
    outfile: "vendor/server/ssr_bundle.js",
    "islands-dir": "app/islands",
  },
});

const ISLANDS_DIR = args["islands-dir"];
const OUT_FILE = args.outfile;
const IS_WATCH = args.watch;
const VERBOSE = args.verbose;

/**
 * Islands ディレクトリから全てのコンポーネントを収集
 */
async function collectIslands(): Promise<Map<string, string>> {
  const islands = new Map<string, string>();
  
  try {
    for await (const entry of walk(ISLANDS_DIR, {
      exts: [".tsx", ".jsx", ".ts", ".js"],
      includeDirs: false,
    })) {
      // ファイル名からコンポーネント名を抽出 (Counter.tsx → Counter)
      const name = entry.name.replace(/\.(tsx?|jsx?)$/, "");
      islands.set(name, entry.path);
      
      if (VERBOSE) {
        console.log(`📦 Found: ${name} (${entry.path})`);
      }
    }
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      console.warn(`⚠️  Islands directory not found: ${ISLANDS_DIR}`);
      console.warn(`   Create it with: mkdir -p ${ISLANDS_DIR}`);
    } else {
      throw error;
    }
  }
  
  return islands;
}

/**
 * エントリーポイントファイルを生成
 */
async function generateEntryPoint(islands: Map<string, string>): Promise<string> {
  const tempFile = await Deno.makeTempFile({ suffix: ".ts" });
  
  const imports: string[] = [];
  const exports: string[] = [];
  
  for (const [name, path] of islands) {
    // 相対パスを絶対パスに変換
    const absPath = await Deno.realPath(path);
    imports.push(`import ${name} from "file://${absPath}";`);
    exports.push(`  "${name}": ${name},`);
  }
  
  const code = `
// Auto-generated entry point for Salvia SSR
// DO NOT EDIT - This file is regenerated on each build

// Preact SSR Runtime
import { h, Fragment } from "https://esm.sh/preact@10.19.3";
import { render as renderToString } from "https://esm.sh/preact-render-to-string@6.4.0";
import htm from "https://esm.sh/htm@3.1.1";

// Bind htm to Preact's h
const html = htm.bind(h);

// Import all Island components
${imports.join("\n")}

// Export to global scope for QuickJS
declare const globalThis: any;

globalThis.SalviaSSR = {
  h,
  Fragment,
  html,
  renderToString,
  
  // Registered components
  components: {
${exports.join("\n")}
  },
  
  // Render a component to HTML string
  render(name: string, props: Record<string, unknown> = {}): string {
    const Component = this.components[name];
    if (!Component) {
      throw new Error(\`Component not found: \${name}. Available: \${Object.keys(this.components).join(", ")}\`);
    }
    
    try {
      const element = h(Component, props);
      return renderToString(element);
    } catch (error) {
      throw new Error(\`SSR Error in \${name}: \${error instanceof Error ? error.message : String(error)}\`);
    }
  }
};

// Also expose individual render function
globalThis.renderIsland = globalThis.SalviaSSR.render.bind(globalThis.SalviaSSR);

console.log("🏝️  Salvia SSR Runtime loaded. Components:", Object.keys(globalThis.SalviaSSR.components));
`;

  await Deno.writeTextFile(tempFile, code);
  return tempFile;
}

/**
 * esbuild でバンドル実行
 */
async function build(entryPoint: string): Promise<void> {
  const startTime = performance.now();
  
  // 出力ディレクトリを作成
  const outDir = OUT_FILE.split("/").slice(0, -1).join("/");
  await Deno.mkdir(outDir, { recursive: true });
  
  try {
    const result = await esbuild.build({
      plugins: [...denoPlugins()],
      entryPoints: [entryPoint],
      outfile: OUT_FILE,
      bundle: true,
      format: "iife",
      platform: "neutral",
      target: "es2020",
      minify: !IS_WATCH, // Watch モードではミニファイしない
      sourcemap: IS_WATCH ? "inline" : false,
      logLevel: VERBOSE ? "info" : "warning",
      
      // QuickJS 互換性のための設定
      define: {
        "process.env.NODE_ENV": IS_WATCH ? '"development"' : '"production"',
      },
    });
    
    if (result.errors.length > 0) {
      console.error("❌ Build errors:");
      for (const error of result.errors) {
        console.error(`   ${error.text}`);
      }
      Deno.exit(1);
    }
    
    const elapsed = (performance.now() - startTime).toFixed(0);
    const stat = await Deno.stat(OUT_FILE);
    const sizeKB = (stat.size / 1024).toFixed(1);
    
    console.log(`✅ Built ${OUT_FILE} (${sizeKB}KB) in ${elapsed}ms`);
    
  } catch (error) {
    console.error("❌ Build failed:", error instanceof Error ? error.message : error);
    Deno.exit(1);
  }
}

/**
 * Watch モードでファイル変更を監視
 */
async function watchMode(): Promise<void> {
  console.log(`👀 Watching ${ISLANDS_DIR} for changes...`);
  
  const watcher = Deno.watchFs(ISLANDS_DIR);
  
  // 初回ビルド
  await runBuild();
  
  // デバウンス用
  let timeout: number | null = null;
  
  for await (const event of watcher) {
    if (event.kind === "modify" || event.kind === "create" || event.kind === "remove") {
      // 300ms デバウンス
      if (timeout) clearTimeout(timeout);
      timeout = setTimeout(async () => {
        console.log(`\n🔄 Change detected: ${event.paths.join(", ")}`);
        await runBuild();
      }, 300);
    }
  }
}

/**
 * ビルド実行
 */
async function runBuild(): Promise<void> {
  const islands = await collectIslands();
  
  if (islands.size === 0) {
    console.log("⚠️  No Island components found.");
    return;
  }
  
  console.log(`🏝️  Found ${islands.size} Island component(s)`);
  
  const entryPoint = await generateEntryPoint(islands);
  
  try {
    await build(entryPoint);
  } finally {
    // 一時ファイルを削除
    await Deno.remove(entryPoint);
  }
}

// メイン処理
if (IS_WATCH) {
  await watchMode();
} else {
  await runBuild();
  esbuild.stop();
}
