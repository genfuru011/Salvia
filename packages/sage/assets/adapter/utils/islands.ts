import { h } from "preact";

// Virtual Module Content for sage/island.tsx
export const SAGE_ISLAND_CONTENT = `
import { h } from "preact";

export function Island({ path, props, children }) {
  return (
    <div
      data-sage-island={path}
      data-props={JSON.stringify(props)}
      style={{ display: "contents" }}
    >
      {children}
    </div>
  );
}
`;

export const sagePlugin = (projectRoot: string) => ({
  name: 'sage-plugin',
  setup(build: any) {
    // 1. Resolve Virtual Modules
    build.onResolve({ filter: /^sage\/island\.tsx$/ }, (args: any) => ({
      path: args.path,
      namespace: 'sage-virtual',
    }));

    build.onLoad({ filter: /.*/, namespace: 'sage-virtual' }, (args: any) => {
      if (args.path === "sage/island.tsx") {
        return { contents: SAGE_ISLAND_CONTENT, loader: 'tsx' };
      }
    });

    // 2. Transform Islands components (Directory based)
    build.onLoad({ filter: /\.tsx$/ }, async (args: any) => {
      // Check if file is in islands directory
      if (!args.path.includes("/app/islands/")) {
        return null;
      }

      const text = await Deno.readTextFile(args.path);
      
      // Avoid infinite loop if already transformed (though onLoad shouldn't trigger on memory content)
      if (text.includes("sage/island.tsx")) {
        return null;
      }

      const relativePath = args.path.replace(projectRoot + '/app/', '');
      
      let newText = text;
      let componentName = "$$IslandComp";

      // Handle export default
      if (newText.match(/export\s+default\s+function\s+\w+/)) {
         const match = newText.match(/export\s+default\s+function\s+(\w+)/);
         if (match) {
           componentName = match[1];
           newText = newText.replace(/export\s+default\s+function/, "function");
         }
      } else if (newText.match(/export\s+default\s+class\s+\w+/)) {
         const match = newText.match(/export\s+default\s+class\s+(\w+)/);
         if (match) {
           componentName = match[1];
           newText = newText.replace(/export\s+default\s+class/, "class");
         }
      } else {
         // export default expression
         newText = newText.replace(/export\s+default/, `const ${componentName} =`);
      }

      // Append wrapper
      newText += `
        import { h } from "preact";
        // import { Island } from "sage/island.tsx"; // Removed to avoid cycle
        
        // Inline Island component to avoid import cycle
        function Island({ path, props, children }) {
          return h("div", { "data-sage-island": path, "data-props": JSON.stringify(props), style: { display: "contents" } }, children);
        }
        
        export default function(props) {
          return h(Island, { path: "${relativePath}", props: props }, h(${componentName}, props));
        }
      `;

      return { contents: newText, loader: 'tsx' };
    });
  },
});
