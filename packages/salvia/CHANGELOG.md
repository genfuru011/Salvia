# Changelog

All notable changes to this project will be documented in this file.

## [0.2.3] - 2025-12-12

### Added
- **New Helpers**: Introduced `salvia_page` (for Full Page SSR) and `salvia_component` (for Partials/Turbo) helpers.
- **API Reference**: Added comprehensive API reference to documentation.

### Deprecated
- **Legacy Helpers**: Deprecated `ssr` and `island` helpers in favor of the new explicit helpers.

## [0.2.2] - 2025-12-12

### Added
- **Full Page SSR Support**: Added `Salvia::SSR.render_page` to automatically inject `<!DOCTYPE html>` and Import Maps.

### Fixed
- **DevServer Routing**: Fixed an issue where requests with extensions (e.g., `.tsx`) were not correctly resolved by the DevServer.
- **Import Map Injection**: Fixed `Uncaught TypeError` in browsers by ensuring Import Maps are present in API Mode responses.

## [0.2.1] - 2025-12-12

### Fixed
- **Sidecar Stability**: Fixed a race condition in Sidecar startup using `onListen` callback.
- **CI/CD**: Fixed CI failures by updating Deno version and workflow configuration.
- **Process Management**: Improved Sidecar process termination logic.
- **Path Handling**: Fixed `build.ts` to handle paths more robustly.
- **Module Compatibility**: Fixed `module.exports` shim in `vendor_setup.ts` for better compatibility.

### Added
- **Cache Busting**: Production builds now generate hashed filenames (e.g., `Counter-a1b2c3d4.js`) to prevent browser caching issues.
- **Thread Safety**: The QuickJS SSR engine is now thread-safe using Thread Local Storage.

### Changed
- **Documentation**: Centralized detailed documentation to English (`docs/en/`) to prevent drift. Japanese documentation is now simplified in `README.ja.md`.

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
