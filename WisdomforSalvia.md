# Wisdom for Salvia: The Architecture of True HTML First

## 1. The Road to ERBless (True HTML First)

Salvia aims to replace the traditional Rails/Sinatra View layer (ERB/Slim) entirely with JSX/TSX, while keeping the robust backend logic of Ruby.

**Architecture Comparison:**

| Feature | Rails (Traditional) | Next.js (App Router) | Salvia (True HTML First) |
| :--- | :--- | :--- | :--- |
| **Routing** | Ruby (routes.rb) | File-system (JS) | Ruby (routes.rb) |
| **Data Fetching** | Ruby (Controller) | JS (Server Components) | Ruby (Controller) |
| **View Logic** | ERB (Ruby) | JSX (React) | **JSX (Preact/React)** |
| **Interactivity** | Stimulus / Turbo | React (Hydration) | **Islands (Hydration)** |
| **Build Step** | Asset Pipeline / Vite | Webpack / Turbopack | **No Build (JIT via Deno)** |

In Salvia, your Ruby controller fetches data from the database (ActiveRecord) and passes it directly to a **Server Component (Page)**. This component is rendered to HTML on the server (SSR) and sent to the browser.

*   **Zero JS by default**: Static content is just HTML.
*   **Islands Architecture**: Only interactive parts (Islands) are hydrated with JavaScript.

## 2. Directory Structure (The "Salvia" Directory)

To separate the frontend concerns from the Ruby backend, Salvia introduces a `salvia/` directory at the project root.

```
my_app/
├── app/                   # Ruby Backend (Controllers, Models)
│   ├── controllers/
│   └── models/
├── config/                # Rails/Sinatra Config
├── salvia/                # Frontend Root (Deno/TypeScript)
│   ├── deno.json          # Import Map & Dependencies
│   ├── vendor_setup.ts    # Bridge for SSR Global Scope
│   └── app/
│       ├── pages/         # Server Components (Entry Points)
│       │   └── Home.tsx
│       ├── islands/       # Client Components (Interactive)
│       │   └── Counter.tsx
│       └── components/    # Shared UI Components
│           └── Button.tsx
└── public/                # Static Assets
```

## 3. Unified Import Management (The "One Config" Strategy)

Salvia v0.2.0 introduces a unified way to manage frontend dependencies using `deno.json`. This single file controls imports for:
1.  **Browser (Client-side)**: Via Import Maps generated in HTML.
2.  **SSR (Server-side)**: Via Deno/QuickJS module resolution.
3.  **Type Checking**: Via Deno's native TypeScript support.

### How it works

You define your dependencies in `salvia/deno.json`:

```json
{
  "imports": {
    // Framework Aliases (Required)
    "framework": "npm:preact@10.19.3",
    "framework/hooks": "npm:preact@10.19.3/hooks",
    "framework/jsx-runtime": "npm:preact@10.19.3/jsx-runtime",
    "framework/ssr": "npm:preact-render-to-string@6.3.1",

    // Other Libraries
    "uuid": "npm:uuid@9.0.1",
    "canvas-confetti": "npm:canvas-confetti@1.9.2"
  }
}
```

**Key Concepts:**

*   **`framework` alias**: Salvia uses this alias internally to support multiple frameworks (Preact, React, etc.) without changing the core logic. You simply point `framework` to your chosen library.
*   **`npm:` specifiers**: Deno uses these to fetch packages from npm. Salvia automatically converts these to `https://esm.sh/...` URLs when generating the Import Map for the browser, ensuring browser compatibility without a build step.

### `vendor_setup.ts` (The Bridge)

To make these ESM modules available to the QuickJS SSR engine (which doesn't natively support `npm:` imports or complex module resolution), we use a bridge file called `salvia/vendor_setup.ts`.

This file imports the framework and libraries using the aliases defined in `deno.json` and exposes them to the global scope for QuickJS.

```typescript
// salvia/vendor_setup.ts
import { h, options } from "framework";
import { renderToString } from "framework/ssr";

// Expose to QuickJS global scope
(globalThis as any).h = h;
(globalThis as any).renderToString = renderToString;

// Setup other globals if needed
import { v4 as uuidv4 } from "uuid";
(globalThis as any).uuidv4 = uuidv4;
```

**Why is this necessary?**
QuickJS is a lightweight engine. By bundling `vendor_setup.ts` using Deno (which understands `npm:` and `deno.json`), we create a single self-contained JavaScript file (`vendor.js`) that contains all your dependencies. QuickJS simply loads this file, and *boom*, `h` and `renderToString` are available globally.

## 4. Multi-Framework Support

Thanks to the `framework` alias strategy, switching frameworks is (theoretically) as simple as updating `deno.json`.

**To use React (Future):**

```json
{
  "imports": {
    "framework": "npm:react@18.2.0",
    "framework/client": "npm:react-dom@18.2.0/client",
    "framework/jsx-runtime": "npm:react@18.2.0/jsx-runtime",
    "framework/ssr": "npm:react-dom@18.2.0/server"
  }
}
```

*Note: React support is currently experimental. Preact is the default and recommended framework for Salvia due to its lightweight nature and compatibility.*

## 5. JIT Compilation & The Sidecar

Salvia uses a "Managed Sidecar" architecture to provide instant feedback during development.

1.  **Rails/Sinatra** starts a background Deno process (`sidecar.ts`).
2.  When you request a page, the **DevServer** middleware intercepts requests for `.js` files.
3.  It asks the **Sidecar** to compile the corresponding `.tsx` file on-the-fly using `esbuild`.
4.  The compiled JS is served to the browser (or used for SSR).

This eliminates the need for a separate `npm run build` or `deno task watch` command. You just run `rails s` or `ruby app.rb`, and Salvia handles the rest.
