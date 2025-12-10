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

Run the install command to generate the necessary configuration and directories:

```bash
$ bundle exec salvia install
```

This creates:
*   `app/islands/` - Directory for your components
*   `deno.json` - Deno configuration
*   `bin/build_ssr.ts` - Build script

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

### 3. Build Components

Compile the components for SSR and the browser:

```bash
$ bundle exec salvia build
# or watch for changes
$ bundle exec salvia watch
```

### 4. Render in Ruby

Use `Salvia::SSR` to render the component in your view (ERB, Slim, etc.):

```ruby
# In your controller or view helper
html = Salvia::SSR.render("Counter", initialCount: 10)
```

To make it interactive on the client, you need to mount it. Salvia provides a helper for this (setup required).

## Configuration

```ruby
Salvia.configure do |config|
  config.islands_dir = "app/islands"
  config.build_dir = "public/assets"
end
```

## Requirements

*   Ruby 3.1+
*   Deno (for building assets only)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
