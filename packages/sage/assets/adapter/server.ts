import { handleRpc } from "./handlers/rpc.ts";
import { handleAsset } from "./handlers/asset.ts";

const SOCKET_PATH = Deno.env.get("SALVIA_SOCKET_PATH");
const PROJECT_ROOT = Deno.env.get("SALVIA_PROJECT_ROOT") || Deno.cwd();
const ADAPTER_ROOT = new URL(".", import.meta.url).pathname;

if (SOCKET_PATH) {
  console.log(`🦕 Deno Adapter listening on ${SOCKET_PATH}`);
  
  // Using Deno.serve for Unix socket support (unstable)
  Deno.serve({ path: SOCKET_PATH }, async (req) => {
    const url = new URL(req.url);
    if (url.pathname.startsWith("/rpc/")) {
      return handleRpc(req, PROJECT_ROOT);
    } else if (url.pathname.startsWith("/assets/")) {
      return handleAsset(req, PROJECT_ROOT, ADAPTER_ROOT);
    }
    return new Response("Not Found", { status: 404 });
  });
} else {
  console.error("SALVIA_SOCKET_PATH not set");
  Deno.exit(1);
}
