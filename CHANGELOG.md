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
- **CLI**: Interactive installer (`salvia install`) with support for Tailwind CSS and framework selection.
- **Tailwind CSS**: Optional integration via `tailwindcss-ruby`.
- **Logging**: `console.log` from JS is forwarded to Ruby logger.
- **Example**: Sinatra application demonstrating SSR, hydration, and Tailwind.

### Fixed
- **Sinatra Compatibility**: Removed dependency on Rails `tag` helper in `Salvia::Helpers::Island`.
- **Deno Configuration**: Removed `nodeModulesDir: auto` to prevent unnecessary `node_modules` creation.
- **QuickJS Persistence**: Fixed log persistence and performance by reusing QuickJS VM instance.

### Changed
- Pivoted from a full-stack MVC framework to a specialized SSR engine.
- Renamed gem from `salvia_rb` to `salvia`.
