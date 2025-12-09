# Salvia.rb Roadmap

> "Wisdom for Rubyists." — A small, understandable Ruby MVC framework

---

## Vision

Salvia.rb fills the gap between "Rails is too heavy" and "Sinatra is too light."

- **Server-rendered HTML first**
- **SSR Islands** for rich UI when needed (No Node.js required)
- **Tailwind CSS** for modern styling
- **ActiveRecord** for database

---

## Completed Phases

### Phase 0: Foundation (v0.1.0) ✅

- [x] `Salvia::Application` - Rack application base class
- [x] `Salvia::Router` - Rails-like DSL routing (Mustermann)
- [x] `Salvia::Controller` - Request/response handling base class
- [x] `render` method - ERB template rendering
- [x] Layout + partial support
- [x] `Salvia::Database` - ActiveRecord connection management

### Phase 1: Developer Experience (v0.2.0) ✅

- [x] Zeitwerk auto-loading
- [x] Code reloading in development
- [x] Custom error pages (404, 500)
- [x] Rack 3.0 compatibility

### Phase 2: Security & Stability (v0.3.0) ✅

- [x] CSRF protection (Rack::Protection)
- [x] Session management (flash messages)
- [x] Routing enhancement (nested resources, named routes)

### Phase 3: Production Ready (v0.4.0) ✅

- [x] Asset digest (cache busting)
- [x] Environment configuration (`config/environments/*.rb`)
- [x] Logging (`Salvia.logger`)
- [x] Testing support (`Salvia::Test::ControllerHelper`)

### Phase 4: SSR Islands Architecture (v0.5.0) ✅

- [x] QuickJS SSR Engine (0.3ms/render)
- [x] `island` helper for Preact components
- [x] Client hydration
- [x] Plugin system
- [x] View components
- [x] Rack 3.x full compatibility

### Phase 5: Architecture Simplification (v0.6.0) ✅

- [x] Removed HTMX plugin and helpers
- [x] Removed Import Map system
- [x] Consolidated SSR to single QuickJS engine
- [x] CLI English-ized
- [x] Simplified configuration

### Phase 6: Documentation (v0.7.0) ✅

- [x] Consolidated docs to 3 files (ARCHITECTURE, GUIDE, ROADMAP)
- [x] Removed outdated Japanese documentation
- [x] Updated CHANGELOG

---

## Current Phase

### Phase 7: CLI UX Enhancement (v0.8.0)

> **"Modern developer experience"**

#### Interactive CLI
- [ ] `salvia new` with prompts (template selection)
- [ ] Templates: Full app / API only / Minimal
- [ ] Islands opt-in during generation

#### Development Workflow
- [ ] `salvia dev` command (server + file watcher)
- [ ] Auto-rebuild Islands on change
- [ ] Better log output (colors, emoji)

#### Code Generators
- [ ] `salvia generate controller NAME`
- [ ] `salvia generate model NAME`
- [ ] `salvia generate migration NAME`

---

## Future Phases

### Phase 8: TypeScript Support (v0.9.0)

- [ ] `salvia types:generate` - Generate TypeScript types from ActiveRecord models
- [ ] `salvia client:generate` - Generate API client from routes
- [ ] TypeScript support in Islands

### Phase 9: Advanced Features (v0.10.0)

- [ ] WebSocket support guide
- [ ] Background job integration guide (Sidekiq / Solid Queue)
- [ ] Multi-tenancy guide

---

## v1.0.0: Stable Release

All features implemented and stable:

- [ ] Complete Getting Started guide
- [ ] API reference documentation
- [ ] Deployment guides (Render, Fly.io, Heroku, Kamal)
- [ ] Performance tuning guide
- [ ] Bug fixes and stabilization

---

## Future (v1.1+)

### salvia-core Gem Extraction

Extract SSR Islands engine as independent gem for use with other frameworks:

```
salvia-core (gem)
├── QuickJS SSR engine
├── Multi-library adapters (Preact/React/Vue/Solid/Svelte)
├── island() helper
├── Rails/Sinatra integration
└── Deno build scripts
```

**Framework Compatibility:**

| Framework | Usage |
|-----------|-------|
| Rails | `gem "salvia-core"` + Railtie |
| Sinatra | `register SalviaCore::Sinatra` |
| Hanami | View helper registration |
| Roda | As plugin |
| Rack | Direct usage |

### Ecosystem

- [ ] Official Island component library (`<salvia-chart>`, `<salvia-editor>`)
- [ ] Admin panel generator (Salvia Admin)

---

## Design Principles

| Principle | Approach |
|-----------|----------|
| Language | English (CLI, logs, errors, docs) |
| Rendering | ERB + SSR Islands only |
| Build | Automatic (watch & rebuild) |
| Packages | esm.sh for JS dependencies |
| Architecture | Simple, explicit, understandable |

---

*Last updated: 2025-12 (v0.7.0)*
