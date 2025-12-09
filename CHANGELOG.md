# Changelog

All notable changes to Salvia.rb will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### In Progress
- TypeScript 型定義生成 (`salvia types:generate`)
- API クライアント生成 (`salvia client:generate`)

---

## [0.5.0] - 2025-01-XX

> **"SSR Islands Architecture"** - Node.js 不要でサーバーサイドレンダリング

### 🏝️ SSR Islands Architecture
- **SSR Engine**: QuickJS ベースの Micro-SSR Engine を実装
  - Preact コンポーネントをサーバーサイドでレンダリング (0.3ms/render)
  - Deno + esbuild で SSR バンドル & クライアントバンドルを生成
  - 本番環境で Node.js 不要
- **`island` ヘルパー**: ERB テンプレートで Island コンポーネントをマウント
  - `<%= island "Counter", { initialCount: 10 } %>`
  - SSR された HTML + クライアントサイドの hydration
- **Import Maps**: `config/importmap.rb` で ESM インポートを管理

### 🔌 Plugin System
- **HTMX プラグイン化**: HTMX がオプショナルプラグインに
  - `config/environment.rb` で `Salvia.use :htmx` で有効化
  - コアは ERB + Islands のみに依存
- **`Salvia::Plugins::Base`**: カスタムプラグインの基底クラス
- **Inspector プラグイン**: 開発用デバッグツール

### 🧩 View Components & Helpers
- **View Components**: `Salvia::Component` と `component` ヘルパー
- **Form Helpers**: `form_tag`, `form_close` (CSRF 対応, method override)
- **HTMX Helpers**: `htmx_link_to`, `htmx_form`, `htmx_trigger`
- **Tag Helpers**: `tag`, `link_to` in `Salvia::Helpers::Tag`
- **Render Options**: `plain:`, `json:`, `partial:` オプション対応

### 🔧 Rack 3.x 互換性
- **ヘッダーの小文字化**: `Content-Type` → `content-type`, `Location` → `location`
- **303 See Other**: POST/PATCH/DELETE 後のリダイレクトに 303 を使用
- **HX-Redirect**: HTMX リダイレクト用ヘッダーも小文字 (`hx-redirect`)

### Fixed
- ERB の HTML エスケープ問題を修正 (`html_safe` サポート)
- ネストした `render` 呼び出しでの重複出力を修正
- `partial:` オプションで自動的にファイル名に `_` を付加

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
