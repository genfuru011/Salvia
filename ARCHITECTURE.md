# Salvia Architecture

> **Ruby Islands Architecture Engine**

---

## Overview

Salvia is a standalone engine that enables **Islands Architecture** in Ruby applications. It allows you to embed interactive JavaScript components (Islands) into server-rendered HTML, without requiring a Node.js server for rendering.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Build Time (Deno)                            │
│  ┌──────────────────┐    ┌─────────────────┐    ┌───────────────┐  │
│  │  app/islands/*.jsx│───▶│   esbuild       │───▶│ SSR Bundle    │  │
│  │                   │    │   (bundler)     │    │ (QuickJS)     │  │
│  │                   │    │                 │    ├───────────────┤  │
│  │                   │    │                 │───▶│ Client Bundle │  │
│  │                   │    │                 │    │ (Browser)     │  │
│  └──────────────────┘    └─────────────────┘    └───────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Runtime (Ruby + QuickJS)                       │
│                                                                     │
│  1. ERB: <%= island "Counter", { initial: 10 } %>                   │
│                         │                                           │
│                         ▼                                           │
│  2. QuickJS: SSR.renderToString("Counter", props) → HTML (0.3ms)   │
│                         │                                           │
│                         ▼                                           │
│  3. Output: <div data-island="Counter" data-props="{...}">          │
│                <div class="counter">10</div>                        │
│             </div>                                                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Client (Browser)                             │
│                                                                     │
│  1. Load islands.js (Preact + Components)                           │
│  2. Find all [data-island] elements                                 │
│  3. hydrate(Component, props, container)                            │
│  4. → Interactive Island!                                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. SSR Engine (`Salvia::SSR`)

**Role:** Executes JavaScript on the server to render components to HTML string.

- **Technology:** [QuickJS](https://bellard.org/quickjs/) (via `quickjs` gem).
- **Performance:** Extremely fast startup and execution (~0.3ms per render).
- **Isolation:** Each render runs in a sandboxed context.

```ruby
# lib/salvia/ssr/quickjs.rb
class QuickJS
  def render(component_name, props = {})
    js_code = "SSR.renderToString('#{component_name}', #{props.to_json})"
    @runtime.eval(js_code)
  end
end
```

### 2. Build System (`salvia build`)

**Role:** Bundles JavaScript components for both Server (SSR) and Client (Hydration).

- **Technology:** [Deno](https://deno.land/) + [esbuild](https://esbuild.github.io/).
- **Why Deno?**
  - Single binary (no `node_modules` hell).
  - Native TypeScript/JSX support.
  - Fast startup.
- **Outputs:**
  - `salvia/server/ssr_bundle.js`: Contains components + `renderToString` function. Loaded by QuickJS.
  - `public/assets/islands/`: Contains client-side bundles for hydration.
  - `public/assets/javascripts/islands.js`: The main hydration script.

### 3. View Helper (`island`)

**Role:** The bridge between Ruby views and the SSR engine.

```ruby
# lib/salvia/helpers/island.rb
def island(name, props = {}, options = {})
  # 1. Render HTML on server
  html = Salvia::SSR.render(name, props)

  # 2. Wrap in a div with data attributes for hydration
  # (Implementation varies by framework to ensure HTML safety)
  build_tag(:div, data: { island: name, props: props.to_json }) { html }
end
```

---

## Integration Flow

Salvia is designed to be framework-agnostic.

1.  **Install**: `salvia install` sets up the directory structure.
2.  **Configure**: `Salvia.configure` tells the engine where to find files.
3.  **Build**: `salvia build` compiles the JavaScript.
4.  **Render**: Use the `island` helper in your framework's view layer.

### Rails Integration

```ruby
# config/initializers/salvia.rb
Salvia.configure do |config|
  config.islands_dir = Rails.root.join("app/islands")
  config.ssr_bundle_path = Rails.root.join("salvia/server/ssr_bundle.js")
end
```

### Sinatra Integration

```ruby
require "sinatra"
require "salvia"

Salvia.configure do |config|
  config.islands_dir = "app/islands"
  config.ssr_bundle_path = "salvia/server/ssr_bundle.js"
end

helpers Salvia::Helpers

get "/" do
  erb :index
end
```

---

## Design Philosophy

1.  **No Node.js at Runtime**: Ruby servers should not depend on a sidecar Node.js process for rendering. QuickJS is embedded and fast.
2.  **Build-time vs Run-time**: Complex bundling happens at build time (Deno). Runtime is simple string generation.
3.  **Progressive Enhancement**: Islands are fully functional HTML first, then hydrated for interactivity.

