# Salvia 🌿

> **Ruby Islands Architecture Engine**

Salvia is a standalone **Server-Side Rendering (SSR) engine** for Ruby. It brings the **Islands Architecture** to any Rack-based application (Rails, Sinatra, Roda, Hanami) without requiring a Node.js server.

<img src="https://img.shields.io/gem/v/salvia?style=flat-square&color=ff6347" alt="Gem">

## Features

*   🏝️ **Islands Architecture**: Render interactive components (Preact) only where needed.
*   🚀 **No Node.js Server**: Uses **QuickJS** embedded in Ruby for fast SSR (0.3ms/render).
*   🦕 **Deno Build System**: Uses Deno + esbuild for bundling (no Webpack/Vite complexity).
*   🔌 **Framework Agnostic**: Works with Rails, Sinatra, or any Rack app.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'salvia'
```

And then execute:

```bash
$ bundle install
```

## Getting Started

### 1. Install SSR files

Run the interactive installer to set up Salvia for your project:

```bash
$ bundle exec salvia install
```

The installer will ask you about:
1.  **Frontend Framework**: (Currently Preact is supported)
2.  **Backend Framework**: (Rails, Sinatra, etc.)
3.  **Tailwind CSS**: (Installs `tailwindcss-ruby` if requested)

This creates:
*   `app/islands/` - Directory for interactive Island components
*   `app/components/` - Directory for shared/static components
*   `salvia/deno.json` - Deno configuration
*   `salvia/build.ts` - Build script
*   `public/assets/islands/` - Output directory for client bundles
*   `public/assets/javascripts/islands.js` - Client-side hydration script

### 2. Create a Component

Create a Preact component in `app/islands/Counter.jsx`:

```jsx
import { h } from 'preact';
import { useState } from 'preact/hooks';

export default function Counter({ initialCount = 0 }) {
  const [count, setCount] = useState(initialCount);
  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
```

### 3. Integration Guide

#### Rails

1.  **Add Script Tag**: Add the hydration script to your layout (`app/views/layouts/application.html.erb`):

    ```erb
    <head>
      <!-- ... -->
      <script type="module" src="/assets/javascripts/islands.js"></script>
    </head>
    ```

2.  **Render Component**: Use the `island` helper in your views:

    ```erb
    <%= island "Counter", initialCount: 10 %>
    ```

3.  **Development**: Create a `Procfile.dev` to run the build watcher alongside your server:

    ```yaml
    web: bin/rails server -p 3000
    salvia: bundle exec salvia watch
    # css: bundle exec tailwindcss -w ... (if using Tailwind)
    ```

    Run with: `bin/dev` or `foreman start -f Procfile.dev`

#### Sinatra

1.  **Setup Application**: Configure Salvia in your app (`app.rb`):

    ```ruby
    require 'sinatra'
    require 'salvia'

    class App < Sinatra::Base
      # 1. Setup Salvia
      Salvia.configure do |config|
        config.islands_dir = "app/islands"
        config.build_dir = "public/assets"
      end

      # 2. Include Helpers
      helpers Salvia::Helpers

      # 3. Serve Static Files (if not already configured)
      use Rack::Static, urls: ["/assets"], root: "public"

      get '/' do
        erb :index
      end
    end
    ```

2.  **Add Script Tag**: Add the hydration script to your layout (`views/layout.erb`):

    ```erb
    <head>
      <!-- ... -->
      <script type="module" src="/assets/javascripts/islands.js"></script>
    </head>
    ```

3.  **Render Component**: Use the `island` helper in your views (`views/index.erb`):

    ```erb
    <%= island "Counter", initialCount: 10 %>
    ```

### 4. Build & Watch

Compile the components for SSR and the browser:

```bash
$ bundle exec salvia build
```

For development, use the watch command to automatically rebuild on changes:

```bash
$ bundle exec salvia watch
```

## Full JSX / ERBless Mode (Experimental)

Salvia supports a "True HTML First" architecture where you can replace ERB views entirely with JSX/TSX Server Components.

### 1. Directory Structure

```
app/
├── pages/             # Server Components (Entry Points)
│   └── Home.tsx       # Renders <html>...</html>
├── components/        # Shared Components
└── islands/           # Client Components (Interactive)
```

### 2. Create a Page Component

`app/pages/Home.tsx`:

```tsx
import { h } from 'preact';
import Counter from '../islands/Counter.jsx';

export default function Home({ title }) {
  return (
    <html>
      <head>
        <title>{title}</title>
        <script type="module" src="/assets/javascripts/islands.js"></script>
      </head>
      <body>
        <h1>{title}</h1>
        <Counter />
      </body>
    </html>
  );
}
```

### 3. Render in Controller

Use the `ssr` helper to render the component as a full HTML page.

**Rails:**

```ruby
def index
  render html: helpers.ssr("pages/Home", title: "Hello Salvia")
end
```

**Sinatra:**

```ruby
get '/' do
  ssr("pages/Home", title: "Hello Salvia")
end
```

The `ssr` helper automatically:
1. Prepends `<!DOCTYPE html>`.
2. Injects the Import Map configuration into `<head>`.
3. Renders the component on the server (no JS sent to client for `pages/`).

## Configuration

```ruby
Salvia.configure do |config|
  config.islands_dir = "app/islands"       # Directory for island components
  config.build_dir = "public/assets"       # Output directory for client assets
  config.ssr_bundle_path = "salvia/server/ssr_bundle.js" # Path to SSR bundle
end
```

## Requirements

*   Ruby 3.1+
*   Deno (for building assets only)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
