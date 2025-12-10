# Salvia Architecture

> **True HTML First Architecture for Ruby**

---

## Overview

Salvia is a next-generation frontend engine for Ruby applications (Rails, Sinatra, Roda, etc.). It brings the **Islands Architecture** and **Server Components** concepts to the Ruby ecosystem, enabling a "True HTML First" approach where you can build modern, interactive UIs using JSX/TSX without abandoning your favorite Ruby framework.

### The "ERBless" Vision

Unlike traditional approaches that embed React components into ERB templates, Salvia allows you to replace the entire View layer with **Server Components** (JSX/TSX).

- **Routing & Data**: Handled by Ruby (Controllers).
- **View Layer**: Handled by Salvia (JSX/TSX Server Components).
- **Interactivity**: Handled by Islands (Hydrated Client Components).

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Development (JIT)                            │
│                                                                     │
│  Request ──▶ [Salvia::DevServer] ──▶ [Managed Sidecar (Deno)]       │
│                     │                          │                    │
│                     ▼                          ▼                    │
│               Asset Serving              JIT Compilation            │
│             (islands.js, etc.)           (esbuild-wasm)             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Runtime (Ruby + QuickJS)                       │
│                                                                     │
│  1. Controller: render ssr("Home", props)                           │
│                         │                                           │
│                         ▼                                           │
│  2. QuickJS: SSR.renderToString("Home", props) → HTML (0.3ms)       │
│                         │                                           │
│                         ▼                                           │
│  3. Output: <html>...<div data-island="Counter">...</div>...</html> │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Client (Browser)                             │
│                                                                     │
│  1. Load HTML (Fast FCP)                                            │
│  2. Load islands.js (Preact + Turbo)                                │
│  3. Hydrate only [data-island] elements                             │
│  4. → Interactive!                                                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

Salvia introduces a dedicated `salvia/` directory at the root of your project, separating frontend concerns from the backend while keeping them co-located.

```
my_app/
├── app/                   # Ruby Backend (Controllers, Models)
├── config/
├── ...
└── salvia/                # Frontend Root
    ├── deno.json          # Import Map & Dependencies (SSOT)
    ├── vendor_setup.ts    # Vendor Library Configuration
    └── app/
        ├── pages/         # Server Components (Entry Points)
        │   ├── Home.tsx   # Replaces app/views/home/index.html.erb
        │   └── layouts/   # Shared Layouts
        ├── components/    # Shared UI Components (Server/Client)
        │   ├── Button.tsx
        │   └── Card.tsx
        └── islands/       # Client Components (Interactive)
            ├── Counter.tsx
            └── Navbar.tsx
```

---

## Core Components

### 1. SSR Engine (`Salvia::SSR`)

**Role:** Executes JavaScript on the server to render components to HTML strings.

- **Technology:** [QuickJS](https://bellard.org/quickjs/) (via `quickjs` gem).
- **Performance:** Extremely fast startup and execution (~0.3ms per render).
- **Isolation:** Each render runs in a sandboxed context.
- **DOM Mocking:** Provides a minimal DOM environment (`document`, `Event`, `URL`, etc.) to support libraries that expect a browser-like environment.

### 2. Managed Sidecar (The "Engine")

**Role:** A long-running Deno process managed by the Ruby application that handles compilation and tooling.

- **Lifecycle:** Automatically started by `Salvia::Compiler` on the first request.
- **Communication:** HTTP over a dynamically assigned TCP port (Port 0).
- **Capabilities:**
  - **JIT Compilation:** Transpiles TSX/JSX to JavaScript on-the-fly using `esbuild`.
  - **Formatting:** Exposes `deno fmt` to Ruby.
  - **Type Checking:** Exposes `deno check` to Ruby.
  - **Import Resolution:** Resolves imports based on `deno.json`.

### 3. JIT Compiler & DevServer

**Role:** Enables a "No Build" experience during development.

- **`Salvia::DevServer`**: A Rack middleware that intercepts requests for JavaScript assets (e.g., `/assets/islands/Counter.js`).
- **On-Demand Compilation**: When an asset is requested, it asks the Sidecar to compile the corresponding TSX file.
- **Source Maps**: Automatically generates inline source maps for debugging.

### 4. Dependency Management (Import Maps)

**Role:** Single Source of Truth (SSOT) for dependencies.

- **`deno.json`**: Defines imports used by both the server (SSR) and the client (Browser).
- **`vendor_setup.ts`**: A special file to re-export npm packages so they can be bundled or served via ESM.
- **Browser Compatibility**: Automatically converts `npm:` specifiers to `https://esm.sh/` URLs for browser usage.

---

## Integration Flow

Salvia is designed to be framework-agnostic.

### Rails Integration

Salvia provides a Railtie that automatically:
1.  Mounts `Salvia::DevServer` in development.
2.  Configures the engine based on `Rails.root`.
3.  Injects helpers into Action Controller.

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.all
    # Renders salvia/app/pages/posts/Index.tsx
    render html: ssr("posts/Index", { posts: @posts })
  end
end
```

### Sinatra Integration

```ruby
require "sinatra"
require "salvia"

Salvia.configure do |config|
  config.root_dir = Dir.pwd
end

helpers Salvia::Helpers

get "/" do
  # Renders salvia/app/pages/Home.tsx
  ssr("Home", { title: "Hello Sinatra" })
end
```

---

## Design Philosophy

1.  **True HTML First**: The server should send fully formed HTML. JavaScript is for enhancement, not rendering.
2.  **Ruby Driven**: The developer experience should feel native to Ruby. No separate `npm run dev` process is required.
3.  **Web Standards**: Built on standard Web APIs (Fetch, ESM, URL) and Deno, avoiding proprietary lock-in.
4.  **Zero Config (mostly)**: Convention over configuration. `deno.json` handles dependencies, and the directory structure dictates behavior.
