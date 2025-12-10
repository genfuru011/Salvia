
import Component from "./_ssr_entry.js";
import { h, hydrate, render } from "https://esm.sh/preact@10.19.3";

export function mount(element, props, options) {
  const vnode = h(Component, props);
  if (options && options.hydrate) {
    hydrate(vnode, element);
  } else {
    render(vnode, element);
  }
}
