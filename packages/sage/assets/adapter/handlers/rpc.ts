import { renderToString } from "preact-render-to-string";
import { h } from "preact";
import { buildPage } from "../utils/build.ts";

const importMap = {
  imports: {
    "preact": "https://esm.sh/preact@10.19.6",
    "preact/jsx-runtime": "https://esm.sh/preact@10.19.6/jsx-runtime?external=preact",
    "preact/hooks": "https://esm.sh/preact@10.19.6/hooks?external=preact",
    "@/": "/assets/app/",
    "sage/": "/assets/sage/"
  }
};

export async function handleRpc(req: Request, projectRoot: string) {
  const url = new URL(req.url);
  const command = url.pathname.replace("/rpc/", "");
  const params = await req.json();
  console.log("RPC params:", params);

  if (command === "render_page") {
    try {
      const pagePath = `${projectRoot}/app/pages/${params.page}.tsx`;
      const code = await buildPage(pagePath, projectRoot);
      const mod = await import(`data:text/javascript;base64,${btoa(code)}`);
      const Page = mod.default;
      const body = renderToString(h(Page, params.props));
      
      return new Response(`
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <title>Sage App</title>
            <script src="https://cdn.tailwindcss.com"></script>
            <script type="importmap">${JSON.stringify(importMap)}</script>
            <script type="module" src="/assets/sage/client.js"></script>
            <script type="module" src="https://esm.sh/@hotwired/turbo@8.0.4"></script>
          </head>
          <body>
            ${body}
          </body>
        </html>
      `, { headers: { "Content-Type": "text/html" } });
    } catch (e) {
      console.error(e);
      return new Response(`Error rendering page ${params.path}: ${e}`, { status: 500 });
    }
  }
  
  if (command === "render_component") {
    try {
      const mod = await import(`${projectRoot}/app/${params.path}.tsx`);
      const Component = mod.default;
      const body = renderToString(h(Component, params.props));
      return new Response(body, { headers: { "Content-Type": "text/html" } });
    } catch (e) {
      console.error(e);
      return new Response(`Error rendering component ${params.path}: ${e}`, { status: 500 });
    }
  }

  return new Response("Unknown RPC command", { status: 400 });
}
