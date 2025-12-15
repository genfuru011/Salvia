import { h, ComponentType } from "preact";

interface IslandProps {
  name: string;
  component: ComponentType<any>;
  [key: string]: any;
}

export default function Island({ name, component: Component, ...props }: IslandProps) {
  return (
    <div data-island={name} data-props={JSON.stringify(props)}>
      <Component {...props} />
    </div>
  );
}
