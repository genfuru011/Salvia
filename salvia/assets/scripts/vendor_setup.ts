import * as preact from "preact";
import * as hooks from "preact/hooks";
import renderToString from "preact-render-to-string";

// Expose to global scope
(globalThis as any).preact = preact;
(globalThis as any).preactHooks = hooks;
(globalThis as any).renderToString = renderToString;
(globalThis as any).h = preact.h;
(globalThis as any).Fragment = preact.Fragment;

// Simple require shim for JIT bundles
(globalThis as any).require = function(moduleName: string) {
  if (moduleName === "preact") return preact;
  if (moduleName === "preact/hooks") return hooks;
  if (moduleName === "preact-render-to-string") return { default: renderToString, renderToString };
  throw new Error("Module not found: " + moduleName);
};
