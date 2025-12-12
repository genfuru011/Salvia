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

// Simple require shim for JIT bundles
(globalThis as any).require = function(moduleName: string) {
  if (moduleName === "preact") return preact;
  if (moduleName === "preact/hooks") return hooks;
  if (moduleName === "@preact/signals") return signals;
  if (moduleName === "preact/jsx-runtime") return jsxRuntime;
  if (moduleName === "preact-render-to-string") return { default: renderToString, renderToString };
  throw new Error("Module not found: " + moduleName);
};

// Shim for module.exports (used by sidecar global-externals)
(globalThis as any).module = { exports: {} };
