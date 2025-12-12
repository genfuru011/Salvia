# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2025-12-12

### Added
- **Zero Config Architecture**: `deno.json` is now the Single Source of Truth (SSOT) for dependencies.
- **Unified Import Management**: `npm:` specifiers are automatically converted to `esm.sh` for browser compatibility.
- **Extensible Globals**: Support for custom global variables in SSR via `salvia.globals` in `deno.json`.
- **Tailwind CSS Integration**: `salvia build` now automatically triggers `tailwindcss:build`.

### Changed
- **Robust Sidecar**: Increased startup timeout to 30s and added crash detection for better stability.
- **Faster First Run**: `salvia install` now caches Deno dependencies to prevent timeouts on the first request.
- **Dynamic Build**: `build.ts` now dynamically loads externals from `deno.json`, preventing bundle bloat.

### Fixed
- Fixed an issue where `externals` were hardcoded in the build script.
- Fixed an issue where Sidecar startup errors were swallowed by timeout exceptions.
- Fixed an issue where CSS was not built during the `salvia build` process.

## [0.1.0] - 2025-12-08

### Added
- **Initial Release**: Introduced Salvia as a next-generation SSR engine for Ruby on Rails.
- **JSX/TSX Support**: Replace ERB views with modern TypeScript components.
- **Islands Architecture**: Hydrate interactive components selectively using Preact.
- **JIT Compilation**: "No Build" development experience powered by a Deno sidecar.
- **QuickJS SSR**: Fast and safe server-side rendering within the Ruby process.
- **Rails Integration**: Seamless integration with Rails controllers and routes via `ssr` helper.
