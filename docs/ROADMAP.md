# Salvia.rb Roadmap

> "Wisdom for Rubyists." — A small, understandable Ruby MVC framework

---

## Vision

Salvia.rb fills the gap between "Rails is too heavy" and "Sinatra is too light."

- **Zero configuration** - Works out of the box, customizable when needed
- **Server-rendered HTML first**
- **SSR Islands** for rich UI when needed (No Node.js required)
- **Tailwind CSS** for modern styling
- **ActiveRecord** for database

---

## Current Version: v0.1.0 ✅

> **"Initial Public Release"** - Published to RubyGems.org

### Core Framework
- [x] `Salvia::Application` - Zero-config Rack application
- [x] `Salvia::Router` - Rails-like DSL routing (Mustermann)
- [x] `Salvia::Controller` - Request/response handling
- [x] `render` method - ERB template rendering
- [x] Layout + partial support
- [x] `Salvia::Database` - ActiveRecord connection management

### Zero Configuration
- [x] Auto-setup with `Salvia::Application.new`
- [x] 3-line `config.ru`
- [x] `Salvia.run!` one-liner startup
- [x] Environment-aware servers (Puma dev / Falcon prod)

### SSR Islands Architecture
- [x] QuickJS SSR Engine (0.3ms/render)
- [x] `island` helper for Preact components
- [x] Client hydration
- [x] Counter component as example

### Developer Experience
- [x] Zeitwerk auto-loading
- [x] Code reloading in development
- [x] Custom error pages (404, 500)
- [x] Interactive CLI with TTY::Prompt
- [x] Code generators (controller, model, migration)

### Security
- [x] CSRF protection (Rack::Protection)
- [x] Session management (flash messages)

### Docker
- [x] Auto-generated Dockerfile
- [x] docker-compose.yml
- [x] .dockerignore

---

## Next Phase

### Phase 1: TypeScript Support (v0.2.0)

> **"Type-safe frontend development"**

- [ ] `salvia types:generate` - Generate TypeScript types from ActiveRecord models
- [ ] `salvia client:generate` - Generate API client from routes
- [ ] TypeScript support in Islands

---

## Future Phases

### Phase 2: Advanced Features (v0.3.0)

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

*Last updated: 2025-12-10 (v0.1.0)*
