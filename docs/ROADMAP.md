# Salvia Roadmap

> **"Ruby Islands Architecture Engine"**

---

## Vision

**Redefine "Salvia" from a "Zero-config MVC Framework" to a "Ruby Islands Architecture Engine".**

Instead of competing with Rails/Hanami, Salvia will become the standard tool for implementing Islands Architecture in the Ruby ecosystem. It will provide the rendering engine, build system, and hydration logic, which can be used within any Rack-based application (including Rails).

---

## Current Version: v0.2.0 (SSR Engine) ✅

> **"The Great Unbundling"** - Pivot to standalone SSR engine

### Core Features
- [x] **SSR Engine**: QuickJS-based rendering (0.3ms/render)
- [x] **Build System**: Deno + esbuild integration
- [x] **Framework Agnostic**: Works with any Rack app
- [x] **CLI**: `install`, `build`, `watch` commands

### Removed (Moved to Archive)
- [x] MVC components (Router, Controller, Database)
- [x] Monolithic application structure

---

## Next Phase

### Phase 1: Framework Integration (v0.3.0)

Make Salvia easy to install into existing frameworks.

- [ ] **Rails Integration**: `Salvia::Railtie` for auto-configuration
- [ ] **Sinatra Integration**: Helper registration
- [ ] **View Helpers**: `island` helper for ERB/Slim/Haml

### Phase 2: Advanced SSR Features (v0.4.0)

- [ ] **TypeScript Support**: Type-safe props passing
- [ ] **Import Maps**: Better dependency management
- [ ] **Multiple Frameworks**: Support for React, Vue, Svelte (currently Preact only)

---

## Future Vision: "Sage" Framework 🔮

> **"Wisdom for Rubyists"**

Once Salvia (the SSR engine) is stable and popular, we will build a new MVC framework **on top of it**.

**Project Name:** `Sage` (Salvia is a type of Sage plant)

**Concept:**
- A lightweight MVC framework
- Uses `salvia` gem as the default view engine
- Zero-config, HTML-first, Islands Architecture by default

```ruby
# Sage Framework (Future)
require "sage"
require "salvia"

class PostsController < Sage::Controller
  def index
    render "posts/index" # Uses Salvia SSR
  end
end
```

---

## Design Principles

| Principle | Approach |
|-----------|----------|
| **Focus** | Do one thing well: SSR Islands |
| **Simplicity** | No Node.js required, minimal dependencies |
| **Speed** | QuickJS for fast rendering, Deno for fast builds |
| **Flexibility** | Work with any Ruby framework |

---

*Last updated: 2025-12-10*
