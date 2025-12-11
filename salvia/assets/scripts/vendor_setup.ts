import { h, Fragment } from "framework";
import * as preact from "framework";
import * as hooks from "framework/hooks";
import * as jsxRuntime from "framework/jsx-runtime";
import renderToString from "framework/ssr";
// import * as Turbo from "@hotwired/turbo";

// Expose to global scope
(globalThis as any).Preact = preact;
(globalThis as any).PreactHooks = hooks;
(globalThis as any).jsxRuntime = jsxRuntime;
(globalThis as any).renderToString = renderToString;
// (globalThis as any).Turbo = Turbo;
(globalThis as any).h = h;
(globalThis as any).Fragment = Fragment;

// Simple require shim for JIT bundles
(globalThis as any).require = function(moduleName: string) {
  if (moduleName === "framework") return preact;
  if (moduleName === "framework/hooks") return hooks;
  if (moduleName === "framework/jsx-runtime") return jsxRuntime;
  if (moduleName === "framework/ssr") return { default: renderToString, renderToString };
  // Legacy support
  if (moduleName === "preact") return preact;
  if (moduleName === "preact/hooks") return hooks;
  if (moduleName === "preact/jsx-runtime") return jsxRuntime;
  if (moduleName === "preact-render-to-string") return { default: renderToString, renderToString };
  throw new Error("Module not found: " + moduleName);
};
