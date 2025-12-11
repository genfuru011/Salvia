# Salvia Roadmap

> **"Ruby Islands Architecture Engine"**

---

## Vision

**Salvia is the "React Server Components" for the Ruby ecosystem.**

Our primary focus is to provide a seamless **Rails + JSX** experience today, while laying the groundwork for **Sage**, a future HTML-first framework.

---

## Current Version: v0.2.0 (Rails + JIT) ✅

> **"True HTML First"** - Full JSX support for Rails

### Core Features
- [x] **SSR Engine**: QuickJS-based rendering (0.3ms/render)
- [x] **JIT Compilation**: "Managed Sidecar" architecture using Deno (No build step)
- [x] **Rails Integration**: Seamless `ssr` helper and Railtie
- [x] **Unified Imports**: `deno.json` manages both Server and Client dependencies
- [x] **Multi-Framework**: Support for Preact (Default) and React (Experimental)

---

## Next Phase

### Phase 1: Stability & Performance (v0.3.0)

- [ ] **Turbo Drive Integration**: First-class support for Turbo transitions with Islands
- [ ] **Production Optimization**: Pre-bundling strategy for deployment
- [ ] **View Component Compatibility**: Interop with GitHub's ViewComponent
- [ ] **Advanced TypeScript**: Automatic type generation for Rails Models/Routes

### Phase 2: The "Sage" Framework (v1.0.0) 🔮

> **"Wisdom for Rubyists"**

Once Salvia is battle-tested in Rails, we will release **Sage**, a standalone MVC framework built around it.

**Concept:**
- **HTML-First**: No JSON APIs by default.
- **Zero-Config**: Deno + Ruby integrated from the start.
- **Islands Architecture**: The default way to build UI.

```ruby
# Sage Framework (Future)
require "sage"

class PostsController < Sage::Controller
  def index
    # Renders app/pages/posts/Index.tsx
    render "posts/Index", posts: Post.all
  end
end
```

---

## Supported Platforms

| Framework | Status | Note |
| :--- | :--- | :--- |
| **Ruby on Rails** | 🟢 **Primary** | First-class support. Recommended for production. |
| **Sinatra** | 🟡 **Supported** | Works via adapter. Good for small apps. |
| **Roda / Hanami** | ⚪ **Planned** | Community contributions welcome. |

---

*Last updated: 2025-12-10*
