# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-10

> **"The Great Unbundling"** - Pivot to standalone SSR engine

### Added
- **SSR Engine**: Standalone Ruby gem (`salvia`) for Server-Side Rendering using QuickJS.
- **Islands Architecture**: Support for partial hydration using Preact.
- **Build System**: Deno + esbuild integration for bundling server and client assets.
- **CLI**: `salvia install`, `salvia build`, and `salvia watch` commands.
- **Tailwind CSS**: Built-in support for Tailwind CSS compilation (optional via `--tailwind`).
- **Logging**: `console.log` from JS is forwarded to Ruby logger.
- **Example**: Sinatra application demonstrating SSR, hydration, and Tailwind.

### Changed
- Pivoted from a full-stack MVC framework to a specialized SSR engine.
- Renamed gem from `salvia_rb` to `salvia`.
