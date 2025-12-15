import { ComponentChildren } from "preact";

interface IslandProps {
  name: string;
  props?: Record<string, any>;
  children?: ComponentChildren;
}

export default function Island({ name, props = {}, children }: IslandProps) {
  return (
    <div data-island={name} data-props={JSON.stringify(props)}>
      {children}
    </div>
  );
}
