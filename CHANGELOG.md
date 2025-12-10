# Changelog

All notable changes to Salvia.rb will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-10

> **"The Great Unbundling"** - Pivot to standalone SSR engine

### 🚀 Major Changes
- **Pivot**: Redefined Salvia as a standalone SSR engine for Ruby.
- **Removed**: All MVC components (Router, Controller, Database, Application).
- **Renamed**: Gem renamed from `salvia_rb` to `salvia`.

### ✨ Features
- **SSR Engine**: Focused on QuickJS-based rendering.
- **CLI**: Simplified to `install`, `build`, `watch` commands.
- **Framework Agnostic**: Can be used with any Rack application.

---

## [0.1.8] - 2025-12-10

> **"Strict Config"** - Enforce all configuration files

### 🔒 Breaking
- `config/app.rb` and `config/database.yml` are now mandatory (`db/` directory must also exist)
- Boot error if `SECRET_KEY` is not set in production environment

### ✅ Added
- Added strict mode tests (app.rb/database.yml/db/ directory/SECRET_KEY)

### ⚙️ Changed
- Raise error immediately instead of suppressing exception when DB setup fails

---

## [0.1.7] - 2025-12-10

### 🔒 Security & Strictness
- **Strict DB Check**: `db/` directory must exist, or app will fail to boot.
- **Error Handling**: Improved error messages for missing configurations.

---

## [0.1.6] - 2025-12-10

### 🐛 Fixes
- **Islands**: Fixed `Counter.js` generation to be `Counter.jsx` for correct syntax highlighting and Deno compatibility.
- **CLI**: Updated templates to match new file extensions.

---

## [0.1.5] - 2025-12-10

### 🐛 Fixes
- **CLI**: Fixed `Salvia.root` undefined error during `salvia new`.
- **Boot**: Fixed `require_app_environment` loading order.

---

## [0.1.4] - 2025-12-10

> **"Explicit Config"** - Moving towards Rails/Hanami style configuration

### 💥 Breaking Changes
- **Config Structure**: Removed `config/environment.rb` in favor of `config/app.rb`.
- **Boot Process**: `Salvia.boot` now requires explicit configuration files.

### ✨ Features
- **Dotenv**: Improved `.env` loading integration.
- **Configuration**: Added `Salvia.configure` block support.

---

## [0.1.3] - 2025-12-10

### 🔧 Internal
- **Gem Packaging**: Fixed file inclusion in gemspec.
- **Dependencies**: Adjusted dependency constraints.

---

## [0.1.2] - 2025-12-10

### 🔧 Internal
- **CLI**: Minor fixes to path resolution.

---

## [0.1.1] - 2025-12-10

> **"JSX & Deno Integration"** - Better DX for Islands development

### 🏝️ Islands Improvements
- **Counter.jsx**: Generate JSX instead of htm template syntax
- **deno.json**: Auto-generate Deno configuration for SSR build
- **Import Maps**: Use bare specifiers (`'preact'`) resolved via deno.json
- **Deno Tasks**: `deno task build` / `deno task watch` commands

### 🔧 Environment
- **dotenv support**: Auto-load `.env`, `.env.local`, `.env.{environment}` files
- **dotenv ~> 3.0**: Added as dependency

### 📚 Documentation
- **Reference guides**: Added REFERENCE_JA.md and REFERENCE_EN.md

---

## [0.1.0] - 2025-12-10

> **"Initial Public Release"** - Zero-config Ruby MVC with SSR Islands

### 🚀 Zero Configuration
- **Auto-setup**: `Salvia::Application.new` configures everything automatically
- **3-line config.ru**: Minimal boilerplate to start
- **`Salvia.run!`**: One-liner startup with environment-aware server selection
- **Environment-aware servers**: Puma (dev) / Falcon (prod) auto-selection

### 🏝️ SSR Islands Architecture
- **QuickJS SSR Engine**: Server-side render Preact components (0.3ms/render)
- **`island` helper**: Mount Preact components in ERB templates
- **Client hydration**: SSR HTML + client-side hydration
- **Counter component**: Included as example in generated apps

### 🎯 Core Framework
- **`Salvia::Application`**: Rack application entry point
- **`Salvia::Router`**: Rails-like DSL (`root`, `resources`, `get`, `post`, etc.)
- **`Salvia::Controller`**: Base class with `render`, `params`, `redirect_to`
- **ERB templates**: Layout + partial support (Tilt + Erubi)
- **ActiveRecord integration**: Database connection management

### 🔧 CLI (`salvia` command)
- `salvia new APP_NAME` - Interactive app generation with templates
- `salvia server` / `salvia s` - Start server (environment-aware)
- `salvia dev` - Server + CSS watch + SSR watch
- `salvia console` / `salvia c` - IRB console with app loaded
- `salvia db:*` - Database commands (create, migrate, rollback, setup)
- `salvia css:build/watch` - Tailwind CSS compilation
- `salvia ssr:build/watch` - SSR bundle building
- `salvia generate` / `salvia g` - Code generators (controller, model, migration)
- `salvia routes` - Display registered routes

### 🐳 Docker Support
- **Auto-generated Dockerfile**: Multi-stage build for production
- **docker-compose.yml**: Ready for development and production
- **.dockerignore**: Optimized for Ruby apps

### 🔒 Security
- **CSRF protection**: Rack::Protection middleware and helpers
- **Flash messages**: `flash` and `flash.now` support
- **Session management**: Cookie-based sessions

### 📦 Gem Internal Assets
- **build_ssr.ts**: Deno build script embedded in gem
- **islands.js**: Client-side hydration script
- **No bin/ folder needed**: All scripts internal to gem

### 🎨 Styling
- **Tailwind CSS**: Configuration with custom Salvia theme
- **`tailwindcss-ruby`**: No Node.js required for CSS

### 📚 Documentation
- Comprehensive README with quick start
- Architecture documentation
- Usage guide with security best practices
- Development roadmap

---

[Unreleased]: https://github.com/genfuru011/Salvia/compare/v0.1.8...HEAD
[0.1.8]: https://github.com/genfuru011/Salvia/releases/tag/v0.1.8
[0.1.1]: https://github.com/genfuru011/Salvia/releases/tag/v0.1.1
[0.1.0]: https://github.com/genfuru011/Salvia/releases/tag/v0.1.0

---

---

## [0.6.0] - Unreleased draft (2025-12-09)

> **"Architecture Simplification"** - Focused, streamlined framework

### 🗑️ Removed
- HTMX plugin and helpers (framework-agnostic now)
- Import Map system
- Unused SSR adapters (quickjs_native, quickjs_wasm, deno)
- Benchmark directory

### 🔧 Refactored
- SSR consolidated to single QuickJS engine
- CLI English-ized (all messages and descriptions)
- Configuration simplified (removed ssr_engine, htmx options)

### 📁 File Structure
- `ssr/adapters/quickjs_hybrid.rb` → `ssr/quickjs.rb`

---

## [0.5.0] - Unreleased draft (2025-12-09)

> **"SSR Islands Architecture"** - Server-side rendering without Node.js

### 🏝️ SSR Islands Architecture
- **SSR Engine**: QuickJS-based Micro-SSR Engine (0.3ms/render)
- **`island` helper**: Mount Preact components in ERB templates
- **Client hydration**: SSR HTML + client-side hydration

### 🔌 Plugin System
- **`Salvia::Plugins::Base`**: Base class for custom plugins
- **Inspector plugin**: Development debug tools

### 🧩 View Components & Helpers
- **View Components**: `Salvia::Component` and `component` helper
- **Form Helpers**: `form_tag`, `form_close` (CSRF, method override)
- **Tag Helpers**: `tag`, `link_to` in `Salvia::Helpers::Tag`
- **Render Options**: `plain:`, `json:`, `partial:` options

### 🔧 Rack 3.x Compatibility
- Lowercase headers (`content-type`, `location`)
- 303 See Other for POST/PATCH/DELETE redirects

### Fixed
- ERB HTML escaping (`html_safe` support)
- Nested `render` call duplicate output
- Partial filename auto-prefix with `_`

## [0.4.0] - Unreleased draft (2025-12-08)

### Added
- **Environment Configuration**: Added support for `config/environments/*.rb` files.
- **Logging**: Added `Salvia.logger` and `config.logger` configuration.
- **Asset Management**: Added `assets:precompile` command and `asset_path` helper for cache busting.
- **Testing Support**: Added `Salvia::Test::ControllerHelper` and `rack-test` integration.
- **Security Documentation**: Added comprehensive security assessment, guide, and checklist.
- **CLI Update**: `salvia new` now generates `config/environments/development.rb` and `production.rb`.

## [0.3.0] - Unreleased draft (2025-12-08)

### Added
- **Flash Messages**: Added `flash` and `flash.now` support for temporary messages.
- **CSRF Protection**: Integrated `Rack::Protection` for CSRF defense.
- **CSRF Helpers**: Added `csrf_token` and `csrf_meta_tags` helpers.
- **HTMX Integration**: Automatic CSRF token injection for HTMX requests.
- **Routing Enhancement**: Added support for nested resources and named routes (e.g., `posts_path`, `post_comments_path`).

## [0.2.0] - Unreleased draft (2025-12-08)

### Added
- **Zeitwerk Integration**: Auto-loading for framework components and application code.
- **Code Reloading**: Automatic code reloading in development environment.
- **Rack 3.0 Support**: Updated dependencies (`rackup`, `rack-session`) for Rack 3.0 compatibility.
- **Custom Error Pages**: Support for `public/404.html` and `public/500.html` in production.
- **CLI Update**: `salvia new` now generates default error pages.

### Fixed
- Fixed `Mustermann` match method compatibility issue.
- Fixed `salvia console` startup arguments for IRB compatibility.
