# Changelog

All notable changes to Salvia.rb will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- TypeScript type generation (`salvia types:generate`)
- WebSocket support guide
- Background job integration guide

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

[Unreleased]: https://github.com/genfuru011/Salvia/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/genfuru011/Salvia/releases/tag/v0.1.0

### Removed
- `docs/design/` directory (merged into ARCHITECTURE.md)
- `docs/development/` directory (merged into GUIDE.md, ROADMAP.md)
- `docs/security/` directory (merged into GUIDE.md)
- `docs/meta/` directory (no longer needed)

---

## [0.6.0] - 2025-12-09

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

## [0.5.0] - 2025-12-09

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

## [0.4.0] - 2025-12-08

### Added
- **Environment Configuration**: Added support for `config/environments/*.rb` files.
- **Logging**: Added `Salvia.logger` and `config.logger` configuration.
- **Asset Management**: Added `assets:precompile` command and `asset_path` helper for cache busting.
- **Testing Support**: Added `Salvia::Test::ControllerHelper` and `rack-test` integration.
- **Security Documentation**: Added comprehensive security assessment, guide, and checklist.
- **CLI Update**: `salvia new` now generates `config/environments/development.rb` and `production.rb`.

## [0.3.0] - 2025-12-08

### Added
- **Flash Messages**: Added `flash` and `flash.now` support for temporary messages.
- **CSRF Protection**: Integrated `Rack::Protection` for CSRF defense.
- **CSRF Helpers**: Added `csrf_token` and `csrf_meta_tags` helpers.
- **HTMX Integration**: Automatic CSRF token injection for HTMX requests.
- **Routing Enhancement**: Added support for nested resources and named routes (e.g., `posts_path`, `post_comments_path`).

## [0.2.0] - 2025-12-08

### Added
- **Zeitwerk Integration**: Auto-loading for framework components and application code.
- **Code Reloading**: Automatic code reloading in development environment.
- **Rack 3.0 Support**: Updated dependencies (`rackup`, `rack-session`) for Rack 3.0 compatibility.
- **Custom Error Pages**: Support for `public/404.html` and `public/500.html` in production.
- **CLI Update**: `salvia new` now generates default error pages.

### Fixed
- Fixed `Mustermann` match method compatibility issue.
- Fixed `salvia console` startup arguments for IRB compatibility.

## [0.1.0] - 2025-12 (Development)

### Added
- **Core Framework**
  - `Salvia::Application` as Rack application entry point
  - `Salvia::Router` with Rails-like DSL (`root`, `resources`, `get`, `post`, etc.)
  - `Salvia::Controller` base class with `render`, `params`, `redirect_to`
  - ERB template rendering with layout support (Tilt + Erubi)
  - Partial rendering with local variables
  - **Smart Rendering**: Auto layout detection for HTMX requests

- **Database Integration**
  - `Salvia::Database` - ActiveRecord connection management
  - `config/database.yml` support with ERB
  - Database commands: `create!`, `drop!`, `migrate!`, `rollback!`
  - SQLite3 as default development database

- **CLI (`salvia` command)**
  - `salvia new APP_NAME` - Generate new application scaffold
  - `salvia server` / `salvia s` - Start development server (Puma)
  - `salvia console` / `salvia c` - Start IRB console
  - `salvia db:create` - Create the database
  - `salvia db:drop` - Drop the database
  - `salvia db:migrate` - Run database migrations
  - `salvia db:rollback` - Rollback migrations
  - `salvia db:setup` - Create and migrate
  - `salvia css:build` - Build Tailwind CSS
  - `salvia css:watch` - Watch and rebuild CSS
  - `salvia routes` - List all routes
  - `salvia version` - Show version

- **Asset Management**
  - HTMX placeholder in `public/assets/javascripts/`
  - Tailwind CSS configuration with `tailwindcss-ruby`
  - Static file serving via `Rack::Static`
  - Custom Salvia color theme for Tailwind

- **Project Generator**
  - Standard MVC directory structure
  - `config.ru` for Rack compatibility
  - `Gemfile` with essential dependencies
  - `Rakefile` with database tasks
  - `tailwind.config.js` with Salvia theme
  - Sample `HomeController` and welcome page
  - `.gitignore` with common patterns

- **Developer Experience**
  - Development error page with stack trace
  - 404 page with registered routes list
  - HTMX request detection (`htmx_request?`)
  - `htmx_trigger` helper for response headers

---

<!-- Future version templates

## [0.2.0] - Unreleased

### Added
- Zeitwerk auto-loading and code reloading
- Enhanced development error page

### Changed
- (Breaking changes, if any)

### Fixed
- (Bug fixes)

## [0.3.0] - Unreleased

### Added
- CSRF protection with Rack::Protection
- Cookie-based session management
- Flash messages (`flash[:notice]`, `flash[:alert]`)
- Named routes (`*_path` helpers)
- Nested resources in router

## [1.0.0] - Unreleased

### Added
- Production deployment guide
- Complete API documentation
- Getting Started guide

### Changed
- Stable API (no more breaking changes in 1.x)

-->

---

[Unreleased]: https://github.com/salvia-rb/salvia/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/salvia-rb/salvia/releases/tag/v0.1.0
