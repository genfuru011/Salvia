import { h, ComponentChildren } from "npm:preact";

interface IslandProps {
  path: string;
  props: Record<string, unknown>;
  children: ComponentChildren;
}

export function Island({ path, props, children }: IslandProps) {
  const jsonProps = JSON.stringify(props);
  const id = `island-${Math.random().toString(36).slice(2)}`;
  
  return (
    <div id={id} style="display: contents;">
      {children}
      <script type="module" dangerouslySetInnerHTML={{ __html: `
        import { hydrate } from "/assets/sage/client.js";
        import Component from "/assets/${path}";
        hydrate("${id}", Component, ${jsonProps});
      ` }} />
    </div>
  );
}
