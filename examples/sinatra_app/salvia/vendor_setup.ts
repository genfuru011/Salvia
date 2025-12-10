import { h, Fragment } from "preact";
import * as preact from "preact";
import * as hooks from "preact/hooks";
import * as jsxRuntime from "preact/jsx-runtime";
import renderToString from "preact-render-to-string";
// import * as Turbo from "@hotwired/turbo";

// Expose to global scope
(globalThis as any).preact = preact;
(globalThis as any).preactHooks = hooks;
(globalThis as any).jsxRuntime = jsxRuntime;
(globalThis as any).renderToString = renderToString;
// (globalThis as any).Turbo = Turbo;
(globalThis as any).h = h;
(globalThis as any).Fragment = Fragment;

// Simple require shim for JIT bundles
(globalThis as any).require = function(moduleName: string) {
  if (moduleName === "preact") return preact;
  if (moduleName === "preact/hooks") return hooks;
  if (moduleName === "preact/jsx-runtime") return jsxRuntime;
  if (moduleName === "preact-render-to-string") return { default: renderToString, renderToString };
  throw new Error("Module not found: " + moduleName);
};
(globalThis as any).Fragment = preact.Fragment;

// Simple require shim for JIT bundles
(globalThis as any).require = function(moduleName: string) {
  if (moduleName === "preact") return preact;
  if (moduleName === "preact/hooks") return hooks;
  if (moduleName === "preact/jsx-runtime") return jsxRuntime;
  if (moduleName === "preact-render-to-string") return { default: renderToString, renderToString };
  throw new Error("Module not found: " + moduleName);
};
