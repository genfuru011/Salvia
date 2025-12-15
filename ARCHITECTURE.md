# Sage Native Architecture (Deno Integration)

This document outlines the architecture for integrating Deno directly into Sage as a sidecar process, replacing the previous Salvia gem implementation.

## 1. Core Concept: "The Dumb Pipe"

Sage (Ruby) acts as the "Brain" (Logic/DB), while Deno acts as the "View Engine" (SSR/Assets). Ruby treats Deno as a black box service, communicating via HTTP over Unix Domain Sockets (UDS).

- **Ruby**: Handles Routing, DB, Auth, and Business Logic.
- **Deno**: Handles HTML Rendering (SSR), Asset Bundling (JIT/AOT), and Import Maps.
- **Protocol**: HTTP over UDS (Unix Domain Socket).

## 2. Directory Structure

The `salvia/` directory is replaced by `adapter/` and `app/` structure.

```text
my_app/
├── app/
│   ├── models/        # ActiveRecord Models
│   ├── pages/         # TSX Pages (SSR Entry)
│   ├── components/    # TSX Components (Shared/Islands)
│   └── resources/     # Sage Resources (Controllers)
├── config/
├── public/
├── deno.json          # Dependencies (SSOT)
└── Gemfile
```

Note: The Deno adapter implementation (`server.ts`, `client.ts`) is hidden within the Sage gem (`packages/sage/assets/adapter/`) to keep the user project clean. `deno.json` remains in the project root for managing dependencies.

## 3. Communication Architecture

### Socket Path
`tmp/sockets/sage_deno.sock`

### A. SSR Request (Ruby -> Deno)
When `ctx.render` is called in a Resource:

1.  **Ruby**: Sends `POST /rpc/render_page` to Deno via UDS.
    *   Body: `{ "page": "Home", "props": { ... } }`
2.  **Deno**:
    *   Dynamically imports `app/pages/Home.tsx`.
    *   Renders to string (Preact).
    *   Injects `<!DOCTYPE html>`, `<head>`, Import Maps, and Client Scripts.
    *   Returns full HTML string.
3.  **Ruby**: Streams the HTML response to the browser.

### B. Asset Request (Browser -> Ruby -> Deno)
When browser requests `/assets/components/Counter.js`:

1.  **Browser**: `GET /assets/components/Counter.js`
2.  **Ruby (`AssetProxy`)**:
    *   Intercepts path starting with `/assets/`.
    *   Forwards request AS-IS to Deno via UDS (`GET /assets/components/Counter.js`).
3.  **Deno**:
    *   Resolves file path.
    *   Transpiles TypeScript to JavaScript (on-the-fly in Dev).
    *   Returns JS content with correct MIME type.
4.  **Ruby**: Streams the response back to the browser.

## 4. Components

### Ruby Side

#### `Sage::Sidecar`
Manages the Deno process and provides the RPC client.
- Uses `Async::HTTP` for non-blocking UDS communication.
- Ensures Deno is running before requests.

#### `Sage::Middleware::AssetProxy`
Rack middleware that proxies `/assets/*` requests to Deno.
- "Dumb" proxy: forwards method, headers, and body.

#### `Sage::Context`
Extended to support Deno rendering.
- `render(page, props)`: Calls `POST /rpc/render_page`.
- `component(path, props)`: Calls `POST /rpc/render_component`.

### Deno Side (`adapter/server.ts`)

Uses `Deno.serve` to listen on the Unix Socket.

- **Router**:
    - `/rpc/render_page`: Full page SSR.
    - `/rpc/render_component`: Fragment rendering.
    - `/assets/*`: Asset serving and transpilation.
- **Error Handling**:
    - Catches rendering errors.
    - Renders a nice `ErrorPage.tsx` with stack trace.
    - Returns HTML with 500 status.

## 5. Hot Reload (HMR)

Uses Server-Sent Events (SSE).

1.  **Browser**: Connects to `/_sage/reload` (handled by Ruby `Sage::Middleware::HMR`).
2.  **Deno**: Watches file system (`Deno.watchFs`).
3.  **Change Detected**: Deno sends `POST http://localhost:3000/_sage/notify` to Ruby.
4.  **Ruby**: Pushes `data: reload` event to all connected SSE clients.
5.  **Browser**: Reloads the page.

## 6. Implementation Status

- [x] **Cleanup**: Remove old Salvia gem code.
- [x] **Deno Adapter**: Implement `adapter/server.ts` with `Deno.serve`.
- [x] **Sage Core**: Implement `Sage::Sidecar` and `Sage::Middleware::AssetProxy`.
- [x] **Context**: Update `Sage::Context#render` to use RPC.
- [x] **HMR**: Implement SSE logic.
- [x] **esbuild**: Implement on-demand compilation in Deno.
- [x] **npm: Support**: Implement automatic `npm:` to `esm.sh` transformation.
- [x] **Islands Architecture**: Implement partial hydration and `sage/client`.
- [x] **Turbo**: Integrate Hotwire/Turbo support.

## 7. Turbo Strategy

Sage uses Turbo Streams for SPA-like partial updates.

### 1. View (Deno)
Assign a unique `id` to the element you want to update. `<turbo-frame>` is not strictly required but recommended.

```tsx
// app/components/TodoItem.tsx
export default function TodoItem({ todo }) {
  return (
    <div id={`todo_${todo.id}`}>
      <form action={`/todos/${todo.id}/toggle`} method="post">
        <button>Toggle</button>
      </form>
    </div>
  );
}
```

### 2. Controller (Ruby)
Return `ctx.turbo_stream` after processing the action.

```ruby
post "/:id/toggle" do |ctx, id|
  todo = Todo.find(id)
  # ... update logic ...
  
  # Instructs the browser to replace the element with id="todo_#{id}"
  # with the rendered result of "components/TodoItem"
  ctx.turbo_stream("replace", "todo_#{id}", "components/TodoItem", todo: todo)
end
```

## 8. Islands Architecture

Sage uses a simple Islands architecture for client-side interactivity.

1.  **Server-Side Rendering**:
    *   Interactive components can be placed anywhere (e.g., `app/components/`).
    *   Add `"use hydration";` at the top of the component file.
    *   During SSR, the server automatically wraps these components in an `<Island>` marker.
    *   The component is rendered to static HTML within this wrapper.

2.  **Client-Side Hydration**:
    *   `client.ts` (injected into every page) scans for `[data-island]` elements (or similar markers).
    *   It dynamically imports the component code.
    *   It hydrates the component using Preact's `hydrate` function.

3.  **RPC**:
    *   Islands can fetch data from the server using `fetch("/resource/rpc_name", { method: "POST" })` or the helper `rpc("resource", "action", params)`.
