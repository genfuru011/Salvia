import * as esbuild from "https://deno.land/x/esbuild@v0.20.1/mod.js";
import { denoPlugins } from "https://deno.land/x/esbuild_deno_loader@0.9.0/mod.ts";
import { sagePlugin } from "./islands.ts";

export async function buildPage(pagePath: string, projectRoot: string) {
  const result = await esbuild.build({
    entryPoints: [pagePath],
    bundle: true,
    write: false,
    format: 'esm',
    platform: 'neutral',
    plugins: [
      sagePlugin(projectRoot),
      ...denoPlugins({ configPath: `${projectRoot}/deno.json` })
    ],
    external: ['preact', 'preact-render-to-string', 'preact/hooks', 'preact/jsx-runtime', '@/sage/*', '@/*'],
    jsx: 'automatic',
    jsxImportSource: 'preact'
  });

  return result.outputFiles[0].text;
}

export async function buildAsset(filePath: string, projectRoot: string) {
    const result = await esbuild.build({
      entryPoints: [filePath],
      bundle: true,
      write: false,
      format: 'esm',
      platform: 'browser',
      plugins: [
        sagePlugin(projectRoot),
        ...denoPlugins({ configPath: `${projectRoot}/deno.json` })
      ],
      external: ['preact', 'preact/hooks', 'preact/jsx-runtime', '@/sage/*', '@/*'],
      jsx: 'automatic',
      jsxImportSource: 'preact'
    });
    return result.outputFiles[0].text;
}
