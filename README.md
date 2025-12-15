# Sage Framework 🌿

**Sage** is a lightweight, high-performance full-stack framework for Ruby, built on **Falcon** and **Deno**.

It combines the elegance of Ruby (Backend) with the modern ecosystem of Deno (Frontend/SSR), providing a "Zero API" development experience similar to Rails but with native React/Preact support.

## Features

*   **Sage Native Architecture**: Ruby acts as a "Dumb Pipe", delegating all rendering and asset serving to a Deno sidecar process.
*   **Zero API**: Pass ActiveRecord objects directly to `ctx.render`. No serializers or API endpoints needed.
*   **Deno SSR**: Server-Side Rendering of Preact components with zero configuration.
*   **On-demand Compilation**: Built-in **esbuild** compiles `.tsx` files on the fly. No Webpack/Vite build steps required.
*   **Turbo Stream Support**: Seamless partial page updates using Hotwire Turbo.
*   **npm: Support**: Use any npm package in your frontend code via `deno.json`.

## Documentation

- [Reference Guide](packages/sage/docs/REFERENCE.md) - Detailed documentation on routing, resources, and frontend integration.
- [Syntax Guide](packages/sage/docs/SYNTAX.md) - Quick reference for Sage syntax.

## Packages

*   **[Sage](packages/sage)**: The core framework.

## Development

This is a monorepo managed with Bundler.

```bash
# Install dependencies
$ bundle install
```

## Directory Structure

```
packages/
└── sage/    # The Sage Framework
demo_app/    # Example application
```
