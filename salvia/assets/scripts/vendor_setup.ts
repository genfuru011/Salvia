import { h, Fragment } from "preact";
import * as preact from "preact";
import * as hooks from "preact/hooks";
import * as signals from "@preact/signals";
import * as jsxRuntime from "preact/jsx-runtime";
import { renderToString } from "preact-render-to-string";

// Expose to global scope for JIT bundles (IIFE)
(globalThis as any).Preact = preact;
(globalThis as any).PreactHooks = hooks;
(globalThis as any).PreactSignals = signals;
(globalThis as any).PreactJsxRuntime = jsxRuntime;
(globalThis as any).renderToString = renderToString;
(globalThis as any).h = h;
(globalThis as any).Fragment = Fragment;

// Module registry for require shim
const moduleRegistry: Record<string, any> = {
  "preact": preact,
  "preact/hooks": hooks,
  "@preact/signals": signals,
  "preact/jsx-runtime": jsxRuntime,
  "preact-render-to-string": { default: renderToString, renderToString }
};

// Simple require shim for JIT bundles
(globalThis as any).require = function(moduleName: string) {
  if (moduleRegistry[moduleName]) return moduleRegistry[moduleName];
  throw new Error(`[Salvia SSR] Module not found: "${moduleName}". If this is an external dependency, ensure it is registered in vendor_setup.ts.`);
};

// Shim for module.exports (used by sidecar global-externals)
(globalThis as any).module = { exports: {} };
