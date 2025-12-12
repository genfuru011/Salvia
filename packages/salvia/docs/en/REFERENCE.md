# Salvia Reference Guide

This guide provides a comprehensive reference for using Salvia in your Ruby on Rails applications.

## 1. Installation

To add Salvia to your Rails application:

1.  **Install Deno** (Required):
    ```bash
    curl -fsSL https://deno.land/x/install/install.sh | sh
    ```

2.  Add the gem to your `Gemfile`:
    ```ruby
    gem 'salvia'
    ```

3.  Install the gem:
    ```bash
    bundle install
    ```

4.  Run the Salvia installer:
    ```bash
    bundle exec salvia install
    ```

This will:
*   Create the `salvia/` directory structure.
*   Generate `deno.json` (SSOT for dependencies).
*   **Cache Deno dependencies** (for faster first run).
*   Update Rails configuration (inject `Salvia::Helpers`).

## 2. Directory Structure

Salvia introduces a dedicated `salvia/` directory at the root of your Rails project to separate frontend concerns.

```
my_app/
├── app/                   # Rails Backend
│   ├── controllers/
│   └── ...
├── salvia/                # Frontend Root
│   ├── app/
│   │   ├── components/    # Shared UI Components (Stateless)
│   │   ├── islands/       # Interactive Client Components (Hydrated)
│   │   └── pages/         # Server Components (SSR only)
│   └── deno.json          # Dependency Management (Import Map)
└── public/
    └── assets/            # Compiled assets (in production)
```

*   **`salvia/app/pages/`**: Entry points for your views. These correspond to Rails views but are written in TSX. They are rendered on the server and sent as HTML.
*   **`salvia/app/islands/`**: Interactive components that need JavaScript on the client. These are "hydrated" automatically.
*   **`salvia/app/components/`**: Reusable UI parts (buttons, cards, layouts) that can be used by both Pages and Islands.

## 3. Core Concepts

### Server Components (Pages)
*   **Location**: `salvia/app/pages/`
*   **Behavior**: Rendered to HTML on the server. No JavaScript is sent to the client for these components.
*   **Use Case**: Layouts, static content, initial data display.

```tsx
// salvia/app/pages/home/Index.tsx
import { h } from 'preact';

export default function Home({ title }) {
  return <h1>{title}</h1>;
}
```

### Client Components (Islands)
*   **Location**: `salvia/app/islands/`
*   **Behavior**: Rendered to HTML on the server, then "hydrated" on the client to become interactive.
*   **Use Case**: Interactive elements like counters, forms, dropdowns.

```tsx
// salvia/app/islands/Counter.tsx
import { h } from 'preact';
import { useState } from 'preact/hooks';

export default function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

### Shared Components
*   **Location**: `salvia/app/components/`
*   **Behavior**: Can be imported by both Pages and Islands.
*   **Use Case**: Design system components.

## 4. Routing & Rendering

Salvia relies on standard Rails routing and controllers.

### The `salvia_page` Helper

To render a Salvia Page from a Rails controller, use the `salvia_page` helper method. This is the recommended approach for Full Page SSR.

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.all
    # Renders salvia/app/pages/posts/Index.tsx
    # Returns full HTML with <!DOCTYPE html> and Import Maps
    render html: salvia_page("posts/Index", posts: @posts)
  end
end
```

*   **First argument**: The path to the component relative to `salvia/app/pages/`.
*   **Second argument**: A hash of props to pass to the component.

> **Note**: The `ssr` helper and `<%= island ... %>` ERB helper are deprecated. Please use `salvia_page` (for full pages) or `salvia_component` (for partials) in your controllers.

## 5. Data Flow

### Props (Server -> Client)
Data flows from your Rails controller to your Page, and then to Islands via **Props**.

```ruby
# Controller
render html: salvia_page("Show", user: @user)
```

```tsx
// Page (Server Component)
export default function Show({ user }) {
  return (
    <div>
      <h1>{user.name}</h1>
      {/* Pass data to Island */}
      <EditProfileForm user={user} />
    </div>
  );
}
```

### Signals (Client State)
For client-side state management, Salvia recommends **Preact Signals**.

```tsx
import { signal } from "@preact/signals";

const count = signal(0);

export default function Counter() {
  return <button onClick={() => count.value++}>{count}</button>;
}
```

## 6. Passing Rails Data to Components

Since Salvia moves the View layer to TSX, you cannot use Rails helpers (like `link_to`, `form_with`, `image_tag`) directly inside your components. Instead, pass the necessary values (URLs, tokens, paths) as **Props** from your controller.

### Example: Handling Forms & CSRF

```ruby
# app/controllers/sessions_controller.rb
def new
  render html: salvia_page("Login", 
    # Pass CSRF token and form action URL
    csrf_token: form_authenticity_token,
    login_path: login_path
  )
end
```

```tsx
// salvia/app/pages/Login.tsx
export default function Login({ csrf_token, login_path }) {
  return (
    <form action={login_path} method="post">
      <input type="hidden" name="authenticity_token" value={csrf_token} />
      
      <label>Email</label>
      <input type="email" name="email" />
      
      <button type="submit">Log In</button>
    </form>
  );
}
```

## 7. Turbo Integration

Salvia is designed to work with Turbo Drive for SPA-like navigation without complex client-side routing.

### Setup
Ensure Turbo is loaded in your layout (e.g., `salvia/app/pages/layouts/Main.tsx`) using the `sage/script` helper.

```tsx
import Script from "sage/script";

<head>
  <Script type="module">
    import * as Turbo from "@hotwired/turbo";
    Turbo.start();
  </Script>
</head>
```

### Turbo Streams
You can return Turbo Stream responses from Rails controllers to update parts of the page dynamically.

```ruby
def create
  @comment = Comment.create(params[:comment])
  # Use salvia_component for partials (no DOCTYPE/ImportMap injection)
  render turbo_stream: turbo_stream.append("comments", html: salvia_component("components/Comment", comment: @comment))
end
```

## 8. Deployment

For production, you need to build the JavaScript assets and CSS.

```bash
bundle exec salvia build
```

This command:
1.  Scans `salvia/app/islands/` for interactive components.
2.  Bundles them into `public/assets/islands/` (**with hashed filenames**).
3.  Generates a production Import Map (`manifest.json`).
4.  **Builds Tailwind CSS** (executes `bin/rails tailwindcss:build`).

Ensure this command is run during your deployment process (e.g., in your Dockerfile or CI/CD pipeline).

## 9. Configuration (deno.json)

Since Salvia v0.2.0, `salvia/deno.json` is the Single Source of Truth (SSOT) for dependencies.

### Adding Dependencies
Add them to the `imports` section. `npm:` specifiers are automatically converted to `esm.sh` for the browser.

```json
{
  "imports": {
    "uuid": "npm:uuid@9.0.0",
    "sage/script": "http://localhost:3000/salvia/assets/components/Script.tsx"
  }
}
```

Note: `sage/script` is automatically served by the dev server.

### Extending Globals (SSR)
If you need to expose specific libraries as global variables in the SSR environment (e.g., `uuid`), use `salvia.globals`.

```json
{
  "salvia": {
    "globals": {
      "uuid": "globalThis.UUID"
    }
  }
}
```

## 10. Sage Integration

Salvia is the default view engine for the **Sage** framework.

```ruby
# config/application.rb
require "sage"
require "salvia"

class App < Sage::Base
  # ...
end
```

When used with Sage, `salvia_page` and `salvia_component` are available via the `ctx` object in your resources.

```ruby
class HomeResource < Sage::Resource
  get "/" do |ctx|
    ctx.render "Home", title: "Welcome to Sage"
  end
end
```

## 11. API Reference

### Helpers (Controllers & Views)

These helpers are available in Rails Controllers and Views.

#### `salvia_page(name, props = {}, options = {})`

Renders a Server Component (Page) as a full HTML document.
**Use this for standard page rendering in Controllers.**

*   **name** (String): Path to the component relative to `salvia/app/pages/` (e.g., `"home/Index"`).
*   **props** (Hash): Props to pass to the component.
*   **options** (Hash):
    *   `doctype` (Boolean): Whether to prepend `<!DOCTYPE html>` (default: `true`).
*   **Returns**: `String` (HTML safe). Automatically injects Import Maps.

#### `salvia_component(name, props = {})`

Renders a component as an HTML fragment.
**Use this for Turbo Streams, Partials, or embedding in other HTML.**

*   **name** (String): Path to the component relative to `salvia/app/` (e.g., `"components/Card"`, `"islands/Counter"`).
*   **props** (Hash): Props to pass to the component.
*   **Returns**: `String` (HTML safe). Does **not** inject Import Maps or DOCTYPE.

### Deprecated Helpers

#### `ssr(name, props = {}, options = {})`
*   **Deprecated**: Use `salvia_page` instead.

#### `island(name, props = {}, options = {})`
*   **Deprecated**: Use `salvia_page` (in Controller) or `salvia_component` instead.
