import { buildAsset } from "../utils/build.ts";

export async function handleAsset(req: Request, projectRoot: string, adapterRoot: string) {
  const url = new URL(req.url);
  let path = url.pathname.replace("/assets/", "");
  
  let filePath;
  if (path.startsWith("sage/")) {
    const relativePath = path.replace(/^sage\//, "");
    filePath = `${adapterRoot}${relativePath}`;
  } else {
    if (path.startsWith("app/")) {
      filePath = `${projectRoot}/${path}`;
    } else {
      filePath = `${projectRoot}/app/${path}`;
    }
  }

  console.log(`[Asset] Request: ${path}, Resolved: ${filePath}`);

  try {
    let finalPath = filePath;
    try {
      await Deno.stat(finalPath);
    } catch {
      if (!path.startsWith("sage/") && !path.startsWith("app/")) {
        const publicPath = `${projectRoot}/public/assets/${path}`;
        try {
          await Deno.stat(publicPath);
          finalPath = publicPath;
        } catch {
          // Continue
        }
      }

      if (finalPath.endsWith(".js")) {
        const tsPath = finalPath.replace(/\.js$/, ".ts");
        try {
          await Deno.stat(tsPath);
          finalPath = tsPath;
        } catch {
           const tsxPath = finalPath.replace(/\.js$/, ".tsx");
           try {
             await Deno.stat(tsxPath);
             finalPath = tsxPath;
           } catch {
             throw new Error("File not found");
           }
        }
      } else {
        throw new Error("File not found");
      }
    }
    
    const code = await buildAsset(finalPath, projectRoot);

    return new Response(code, {
      headers: { "Content-Type": "application/javascript" }
    });
  } catch (e) {
    console.error(`Asset error for ${path}:`, e);
    return new Response("Not Found", { status: 404 });
  }
}
