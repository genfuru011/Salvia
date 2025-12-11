# Salvia Reference Guide

This guide provides a comprehensive reference for using Salvia in your Ruby on Rails applications.

## 1. Installation

To add Salvia to your Rails application:

1.  Add the gem to your `Gemfile`:
    ```ruby
    gem 'salvia'
    ```

2.  Install the gem:
    ```bash
    bundle install
    ```

3.  Run the Salvia installer:
    ```bash
    bundle exec salvia install
    ```

This will create the `salvia/` directory structure and necessary configuration files.

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

### The `ssr` Helper

To render a Salvia Page from a Rails controller, use the `ssr` helper method.

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.all
    # Renders salvia/app/pages/posts/Index.tsx
    render html: ssr("posts/Index", posts: @posts)
  end
end
```

*   **First argument**: The path to the component relative to `salvia/app/pages/`.
*   **Second argument**: A hash of props to pass to the component.

## 5. Data Flow

### Props (Server -> Client)
Data flows from your Rails controller to your Page, and then to Islands via **Props**.

```ruby
# Controller
render html: ssr("Show", user: @user)
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

## 6. Turbo Integration

Salvia is designed to work with Turbo Drive for SPA-like navigation without complex client-side routing.

### Setup
Ensure Turbo is loaded in your layout (e.g., `salvia/app/pages/layouts/Main.tsx`).

```tsx
<head>
  <script type="module">
    import * as Turbo from "https://esm.sh/@hotwired/turbo@8.0.0";
    Turbo.start();
  </script>
</head>
```

### Turbo Streams
You can return Turbo Stream responses from Rails controllers to update parts of the page dynamically.

```ruby
def create
  @comment = Comment.create(params[:comment])
  render turbo_stream: turbo_stream.append("comments", html: ssr("components/Comment", comment: @comment))
end
```

## 7. Deployment

For production, you need to build the JavaScript assets.

```bash
bundle exec salvia build
```

This command:
1.  Scans `salvia/app/islands/` for interactive components.
2.  Bundles them into `public/assets/islands/`.
3.  Generates an import map for production use.

Ensure this command is run during your deployment process (e.g., in your Dockerfile or CI/CD pipeline).
