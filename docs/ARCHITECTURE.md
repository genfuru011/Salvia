# Salvia.rb Architecture

> Internal architecture and design philosophy of the framework

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        HTTP Request                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Rack Middleware                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Rack::Static│  │Rack::Session│  │  Rack::Protection   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Salvia::Application                       │
│                    (Rack App Entry)                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Salvia::Router                          │
│              ┌────────────────────────┐                     │
│              │   Route Matching       │                     │
│              │   (Mustermann)         │                     │
│              └────────────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Salvia::Controller                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐  │
│  │  params  │  │  render  │  │ redirect │  │   session   │  │
│  └──────────┘  └──────────┘  └──────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    View Rendering                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Tilt + Erubi (ERB)                      │   │
│  │  ┌────────────┐  ┌────────────┐  ┌───────────────┐   │   │
│  │  │   Layout   │  │  Template  │  │    Partial    │   │   │
│  │  └────────────┘  └────────────┘  └───────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       HTML Response                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Salvia::Application

**Role:** Rack application entry point

```ruby
class Application
  def call(env)
    request = Rack::Request.new(env)
    response = Rack::Response.new
    handle_request(request, response)
    response.finish
  end
end
```

**Responsibilities:**
- Implements Rack interface (`call(env)`)
- Dispatches to Router
- Error handling (development/production)
- 404/500 page generation

---

### 2. Salvia::Router

**Role:** URL pattern matching and routing to controllers

```ruby
Router.draw do
  root to: "home#index"
  get "/posts/:id", to: "posts#show"
  resources :comments
end
```

**Design:**

| Item | Implementation |
|------|----------------|
| Pattern Matching | Mustermann (`:rails` type) |
| DSL | `root`, `get`, `post`, `resources` |
| Singleton | Global access via `Router.instance` |
| Route Structure | `Route` Struct (method, pattern, controller, action) |

---

### 3. Salvia::Controller

**Role:** Request processing and response generation

```ruby
class PostsController < Salvia::Controller
  def show
    @post = Post.find(params["id"])
    render "posts/show"
  end
end
```

**Key Methods:**

| Method | Description |
|--------|-------------|
| `params` | Merged URL + query/body parameters |
| `render(template, locals:, layout:, status:)` | ERB template rendering |
| `render_partial(template, locals:)` | Partial rendering (no layout) |
| `redirect_to(url, status:)` | Redirect response |
| `session` | Session hash |
| `flash` | Flash messages |

---

### 4. Salvia::Database

**Role:** ActiveRecord connection management

```ruby
Database.setup!      # Establish connection
Database.migrate!    # Run migrations
Database.create!     # Create database
Database.drop!       # Drop database
```

**Supported Adapters:**
- SQLite3 (default)
- PostgreSQL
- MySQL

---

### 5. SSR Islands Architecture

**Role:** Server-side rendering of Preact components with QuickJS

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Build Time (Deno)                            │
│  ┌──────────────────┐    ┌─────────────────┐    ┌───────────────┐  │
│  │  app/islands/*.jsx│───▶│   esbuild       │───▶│ SSR Bundle    │  │
│  │                   │    │   (bundler)     │    │ (QuickJS)     │  │
│  │                   │    │                 │    ├───────────────┤  │
│  │                   │    │                 │───▶│ Client Bundle │  │
│  │                   │    │                 │    │ (Browser)     │  │
│  └──────────────────┘    └─────────────────┘    └───────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Runtime (Ruby + QuickJS)                       │
│                                                                     │
│  1. ERB: <%= island "Counter", { initial: 10 } %>                   │
│                         │                                           │
│                         ▼                                           │
│  2. QuickJS: SSR.renderToString("Counter", props) → HTML (0.3ms)   │
│                         │                                           │
│                         ▼                                           │
│  3. Output: <div data-island="Counter" data-props="{...}">          │
│                <div class="counter">10</div>                        │
│             </div>                                                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Client (Browser)                             │
│                                                                     │
│  1. Load islands.js (Preact + Components)                           │
│  2. Find all [data-island] elements                                 │
│  3. hydrate(Component, props, container)                            │
│  4. → Interactive Island!                                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**SSR Engine (QuickJS):**
```ruby
# lib/salvia_rb/ssr/quickjs.rb
class QuickJS
  def render(component_name, props = {})
    js_code = "SSR.renderToString('#{component_name}', #{props.to_json})"
    @runtime.eval(js_code)  # 0.3ms/render
  end
end
```

**island Helper:**
```ruby
def island(name, props = {})
  html = Salvia::SSR.render(name, props)
  %(<div data-island="#{name}" data-props="#{escape_html(props.to_json)}">#{html}</div>).html_safe
end
```

---

### 6. CLI (Thor)

**Role:** Command-line interface

```
salvia
├── new APP_NAME      # Generate app
├── server (s)        # Start server
├── console (c)       # Start IRB
├── db:create         # Create database
├── db:drop           # Drop database
├── db:migrate        # Run migrations
├── db:rollback       # Rollback migration
├── db:setup          # create + migrate
├── css:build         # Tailwind build
├── css:watch         # Tailwind watch
├── islands:build     # Build SSR bundle
├── routes            # List routes
└── version           # Show version
```

---

## Design Principles

### 1. Explicitness > Implicitness

Unlike Rails' "convention over configuration", Salvia values explicit code:

```ruby
# Salvia: explicit render call
def index
  @posts = Post.all
  render "posts/index"  # explicit
end
```

### 2. Simplicity > Features

- Minimal metaprogramming
- Code behavior is obvious from reading
- "Understanding" over "magic"

### 3. HTML First

- Return HTML, not JSON API
- Use SSR Islands for rich UI when needed
- Avoid SPA complexity

### 4. Minimal Dependencies

| Dependency | Purpose | Reason |
|------------|---------|--------|
| rack | HTTP abstraction | Standard Ruby web interface |
| mustermann | Routing | Battle-tested in Sinatra |
| tilt + erubi | Templating | Lightweight and fast |
| activerecord | ORM | Ruby de facto standard |
| thor | CLI | Easy-to-use CLI DSL |
| zeitwerk | Autoloader | Rails standard, reliable |
| quickjs | SSR | Fast JS execution in Ruby |

---

## Gem Source Structure

```
salvia_rb/
├── exe/
│   └── salvia                    # CLI entry point
├── lib/
│   ├── salvia_rb.rb              # Main module
│   └── salvia_rb/
│       ├── version.rb            # Version definition
│       ├── router.rb             # Routing DSL (Mustermann)
│       ├── controller.rb         # Controller base class
│       ├── application.rb        # Rack application
│       ├── database.rb           # ActiveRecord connection
│       ├── assets.rb             # Asset management
│       ├── flash.rb              # Flash messages
│       ├── test.rb               # Test support
│       ├── cli.rb                # Thor CLI
│       ├── ssr.rb                # SSR entry point
│       ├── ssr/
│       │   └── quickjs.rb        # QuickJS SSR engine
│       └── helpers/
│           ├── tag.rb            # Tag helpers
│           ├── island.rb         # Island helper
│           └── component.rb      # Component helper
└── salvia_rb.gemspec
```

---

## Generated App Structure

```
myapp/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── home_controller.rb
│   ├── models/
│   │   └── application_record.rb
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.html.erb
│   │   └── home/
│   │       └── index.html.erb
│   ├── islands/                  # Preact components (optional)
│   │   └── Counter.jsx
│   └── components/               # ERB components (optional)
├── config/
│   ├── database.yml
│   ├── environment.rb
│   ├── environments/
│   │   ├── development.rb
│   │   └── production.rb
│   └── routes.rb
├── db/
│   └── migrate/
├── public/
│   └── assets/
│       ├── javascripts/
│       │   └── islands.js
│       └── stylesheets/
│           └── tailwind.css
├── test/
├── bin/
│   └── build_ssr.ts              # Deno build script (if Islands)
├── vendor/
│   └── server/
│       └── ssr_bundle.js         # SSR bundle (if Islands)
├── config.ru
├── Gemfile
├── Rakefile
└── tailwind.config.js
```

---

## Request Lifecycle

```
1. HTTP Request arrives
   └─▶ config.ru
       └─▶ Rack::Static (static files)
       └─▶ Rack::Session (session)
       └─▶ Rack::Protection (security)
       └─▶ Salvia::Application#call

2. Routing
   └─▶ Salvia::Router.recognize(request)
       └─▶ Mustermann pattern matching
       └─▶ Returns [ControllerClass, action, params]

3. Controller Processing
   └─▶ controller = ControllerClass.new(request, response, params)
   └─▶ controller.process(action)
       └─▶ Action method
       └─▶ render / redirect_to

4. View Rendering
   └─▶ Tilt.new(template_path)
   └─▶ template.render(self, locals)
   └─▶ Layout wrapping (unless partial)

5. Response
   └─▶ response.finish
   └─▶ [status, headers, body]
```

---

## Comparison with Other Frameworks

| Feature | Salvia | Rails | Sinatra | Hanami |
|---------|--------|-------|---------|--------|
| Size | Tiny | Large | Tiny | Medium |
| Learning Curve | Low | High | Low | Medium |
| SSR Islands | Built-in | No | No | No |
| ORM | ActiveRecord | ActiveRecord | Choice | ROM |
| Auto-loading | Zeitwerk | Zeitwerk | Manual | Zeitwerk |
| Node.js Required | No | Optional | No | Optional |
| Zero Config | Yes | No | No | No |
| Docker Ready | Auto-gen | Manual | Manual | Manual |

---

*Last updated: 2025-12-10 (v0.1.0)*
