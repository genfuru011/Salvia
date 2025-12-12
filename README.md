# Salvia 🌿

> **The Future of Rails View Layer**

Salvia is a next-generation **Server-Side Rendering (SSR) engine** designed to replace ERB with **JSX/TSX** in Ruby on Rails. It brings the **Islands Architecture** and **True HTML First** philosophy to the Rails ecosystem.

<img src="https://img.shields.io/gem/v/salvia?style=flat-square&color=ff6347" alt="Gem">

## Vision: The Road to Sage

Salvia is the core engine for a future MVC framework called **Sage**.
While Sage will be a complete standalone framework, Salvia is available *today* as a drop-in replacement for the View layer in **Ruby on Rails**.

## Features

*   🏝️ **Islands Architecture**: Render interactive components (Preact/React) only where needed. Zero JS for static content.
*   🚀 **True HTML First**: Replace `app/views/**/*.erb` with `app/pages/**/*.tsx`.
*   ⚡ **JIT Compilation**: No build steps during development. Just run `rails s`.
*   💎 **Rails Native**: Seamless integration with Controllers, Routes, and Models.
*   🦕 **Deno Powered**: Uses Deno for lightning-fast TypeScript compilation and formatting.

## Requirements

*   Ruby 3.1+
*   Rails 7.0+ (Recommended)
*   **Deno 1.30+** (Required for JIT compilation and tooling)

## Installation

### 1. Install Deno

Salvia requires Deno. Follow the [official installation guide](https://deno.land/#installation).

```bash
# macOS / Linux
$ curl -fsSL https://deno.land/x/install/install.sh | sh
```

### 2. Add Gem

Add this line to your Rails application's Gemfile:

```ruby
gem 'salvia'
```

And then execute:

```bash
$ bundle install
```

## Getting Started

### 1. Setup Salvia

Run the interactive installer to set up Salvia for your Rails project:

```bash
$ bundle exec salvia install
```

This command will:
1.  Create the `salvia/` directory structure.
2.  Generate `deno.json` (Single Source of Truth for dependencies).
3.  **Cache Deno dependencies** to ensure fast startup.
4.  Configure Rails to automatically include `Salvia::Helpers` (providing the `ssr` method).

#### Directory Structure

```
salvia/
├── app/
│   ├── components/  # Shared UI components (Buttons, Cards)
│   ├── islands/     # Interactive components (Hydrated on client)
│   └── pages/       # Server Components (SSR only, 0kb JS to client)
└── deno.json        # Dependency management (Import Map)
```

### 2. Create a Page (Server Component)

Delete `app/views/home/index.html.erb` and create `salvia/app/pages/home/Index.tsx`:

```tsx
import { h } from 'preact';

export default function Home({ title }) {
  return (
    <div class="p-10">
      <h1 class="text-3xl font-bold">{title}</h1>
      <p>This is rendered on the server with 0kb JavaScript sent to the client.</p>
    </div>
  );
}
```

### 3. Render in Controller

In your Rails controller:

```ruby
class HomeController < ApplicationController
  def index
    # Renders salvia/app/pages/home/Index.tsx
    render html: ssr("home/Index", title: "Hello Salvia")
  end
end
```

### 4. Add Interactivity (Islands)

Create an interactive component in `salvia/app/islands/Counter.tsx`:

```tsx
import { h } from 'preact';
import { useState } from 'preact/hooks';

export default function Counter() {
  const [count, setCount] = useState(0);
  return (
    <button onClick={() => setCount(count + 1)} class="btn">
      Count: {count}
    </button>
  );
}
```

Use it in your Page:

```tsx
import Counter from '../../islands/Counter.tsx';

export default function Home() {
  return (
    <div>
      <h1>Interactive Island</h1>
      <Counter />
    </div>
  );
}
```

### 4. Turbo Drive (Optional)

Salvia works seamlessly with Turbo Drive for SPA-like navigation.

Add Turbo to your layout file (e.g., `app/pages/layouts/Main.tsx`):

```tsx
<head>
  {/* ... */}
  <script type="module">
    import * as Turbo from "https://esm.sh/@hotwired/turbo@8.0.0";
    Turbo.start();
  </script>
</head>
```

This approach leverages Import Maps and browser-native modules, keeping your bundle size small and your architecture transparent.

## Core Concepts: Pages vs Islands

Understanding the separation of concerns is crucial for "True HTML First" development.

| Feature | **Pages (Server Components)** | **Islands (Client Components)** |
| :--- | :--- | :--- |
| **Path** | `salvia/app/pages/` | `salvia/app/islands/` |
| **Environment** | Server (Ruby/QuickJS) | Client (Browser) |
| **Interactivity** | ❌ Static HTML | ✅ Interactive (Event Listeners) |
| **State** | ❌ Stateless | ✅ Stateful (Signals/Hooks) |
| **Browser APIs** | ❌ No (`window`, `document` are mocked) | ✅ Yes |
| **Usage** | Layouts, Initial Data Fetching | Forms, Modals, Dynamic UI |

## Documentation

*   **English**:
    *   [**Wisdom for Salvia**](docs/en/DESIGN.md): Deep dive into the architecture, directory structure, and "True HTML First" philosophy.
    *   [**Reference Guide**](docs/en/REFERENCE.md): Comprehensive guide on usage, API, and configuration.
    *   [**Architecture**](docs/en/ARCHITECTURE.md): Internal design of the gem.
*   **Japanese (日本語)**:
    *   [**README**](README.ja.md): 日本語版README。

## Framework Support

Salvia is primarily designed for **Ruby on Rails** to pave the way for the **Sage** framework.

*   **Ruby on Rails**: First-class support.

## Zero Config Architecture

Salvia v0.2.0 adopts a **Zero Config** philosophy.

*   **`deno.json` is SSOT**: It manages dependencies for both Server (SSR) and Client (Browser).
*   **Auto Import Map**: `npm:` specifiers in `deno.json` are automatically converted to `esm.sh` URLs for the browser.
*   **No Build Config**: `build.ts` and `sidecar.ts` are managed internally, but you can extend globals via `salvia.globals` in `deno.json`.

## Production & CI

In production environments (e.g., Docker, Heroku, Render):

1.  **Deno is required**: Ensure Deno is installed in your build/runtime environment.
2.  **Build Step**: Run `bundle exec salvia build` during deployment.
    *   This bundles Islands, generates Import Maps, and builds Tailwind CSS.
    *   It generates hashed filenames for cache busting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
