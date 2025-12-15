# Implementation Notes - Sage Native Deno Integration

## Overview
We have successfully integrated Deno as a sidecar process for Sage, replacing the legacy Salvia gem. This provides a robust, high-performance SSR and asset pipeline.

## Key Changes

### 1. Architecture
- **Ruby (Sage)**: Handles routing, database, and business logic.
- **Deno (Adapter)**: Handles SSR (Preact), asset bundling (esbuild), and client-side hydration.
- **Communication**: HTTP over Unix Domain Sockets (UDS).

### 2. "Use Hydration" Support
- Components can be marked for client-side hydration by adding `"use hydration";` at the top of the file.
- The Deno server (via esbuild plugin) automatically transforms these components during SSR to wrap them in an `<Island>` marker.
- **v2.2 Update**: `sage/island.tsx` is now a virtual module embedded in `server.ts`, and the transformation logic correctly handles various `export default` patterns to prevent duplicate exports.
- The client script (`client.js`) hydrates these islands automatically.

### 3. Asset Pipeline
- Assets in `app/` are served via `/assets/`.
- TypeScript/TSX is transpiled on-the-fly by Deno using esbuild.
- `npm:` imports are supported and transformed to `esm.sh` URLs for browser compatibility.

### 4. Hot Reload (HMR)
- Deno watches the file system and notifies Ruby via a private HTTP endpoint.
- Ruby broadcasts reload events to the browser via Server-Sent Events (SSE).

### 5. Project Structure
- `app/pages/`: Top-level pages (SSR entry points).
- `app/components/`: Reusable components (can be islands).
- `deno.json`: Manages frontend dependencies.

## Debugging
- Deno logs are piped to the Sage server output.
- If Deno fails to start, check `tmp/sockets/sage_deno.sock` and `tmp/pids/sage_deno.pid`.
- Ensure `deno` is in your PATH.

## Future Improvements
- Production build step (AOT compilation).
- More robust error handling for hydration failures.
- Support for other frameworks (React, Vue) via adapter configuration.

### 6. Turbo & CDN
- Turbo Drive is included by default for SPA-like navigation.
- We use `esm.sh` as the CDN for Turbo and other browser dependencies to ensure compatibility and reliability.

### 7. Automatic Hydration
- The `client.js` script (served from `packages/sage/assets/adapter/sage/client.ts`) now includes automatic hydration logic.
- It scans the DOM for elements with `data-sage-island` attributes.
- It dynamically imports the corresponding component using the Import Map (`@/` alias).
- It hydrates the component with the serialized props.
