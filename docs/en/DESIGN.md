# Wisdom for Salvia: The Architecture of True HTML First

## 1. The Road to Sage (Vision)

Salvia is not just a view engine; it is the foundational technology for **Sage**, a future Ruby MVC framework designed from the ground up for the "True HTML First" era.

While Sage is in development, Salvia brings this futuristic architecture to **Ruby on Rails** today. It allows Rails developers to abandon ERB/Slim and adopt a modern, component-based frontend workflow without leaving the Ruby ecosystem.

## 2. The Architecture: Rails + JSX

Salvia replaces the traditional Rails View layer entirely with JSX/TSX, while keeping the robust backend logic of Ruby (Controllers & Models).

**Architecture Comparison:**

| Feature | Rails (Traditional) | Next.js (App Router) | Salvia (Rails + JSX) |
| :--- | :--- | :--- | :--- |
| **Routing** | Ruby (routes.rb) | File-system (JS) | Ruby (routes.rb) |
| **Data Fetching** | Ruby (Controller) | JS (Server Components) | Ruby (Controller) |
| **View Logic** | ERB (Ruby) | JSX (React) | **JSX (Preact/React)** |
| **Interactivity** | Stimulus / Turbo | React (Hydration) | **Islands (Hydration)** |
| **Build Step** | Asset Pipeline / Vite | Webpack / Turbopack | **No Build (JIT via Deno)** |

In Salvia, your Rails controller fetches data from the database (ActiveRecord) and passes it directly to a **Server Component (Page)**. This component is rendered to HTML on the server (SSR) and sent to the browser.

*   **Zero JS by default**: Static content is just HTML.
*   **Islands Architecture**: Only interactive parts (Islands) are hydrated with JavaScript.

## 3. Directory Structure (The "Salvia" Directory)

To separate the frontend concerns from the Ruby backend, Salvia introduces a `salvia/` directory at the project root.

```
my_app/
├── app/                   # Ruby Backend (Controllers, Models)
│   ├── controllers/
│   └── models/
├── config/                # Rails Config
├── salvia/                # Frontend Root (Deno/TypeScript)
│   └── app/
│       ├── pages/         # Server Components (Entry Points)
│       │   └── Home.tsx
│       ├── islands/       # Client Components (Interactive)
│       │   └── Counter.tsx
│       └── components/    # Shared UI Components
│           └── Button.tsx
└── public/                # Static Assets
```

## 4. Zero Config Architecture (Internalized Complexity)

Salvia v0.2.0 adopts a **Zero Config** philosophy, inspired by Next.js and Fresh.

### Internalized Configuration
Previously exposed configuration files like `vendor_setup.ts` are now internalized within the Salvia gem. `deno.json` remains in your project root as the Single Source of Truth for dependencies. This means:

1.  **No Boilerplate**: You don't need to manage complex build configurations or import maps.
2.  **Preact Only**: Salvia is opinionated and strictly enforces a Preact + Signals architecture for maximum performance and compatibility.
3.  **Automatic Import Maps**: Salvia automatically generates Import Maps for the browser based on its internal configuration, ensuring that `preact`, `preact/hooks`, and `@preact/signals` just work.

### How it works under the hood

While complex configuration files like `vendor_setup.ts` are hidden, `deno.json` remains exposed in your project root. This allows you to easily manage dependencies:

1.  **Browser (Client-side)**: Via Import Maps generated in HTML.
2.  **SSR (Server-side)**: Via Deno/QuickJS module resolution using the internal `deno.json`.
3.  **Type Checking**: Via Deno's native TypeScript support.

**Key Concepts:**

*   **Preact First**: Salvia is built on Preact for its lightweight nature and powerful Signals architecture.
*   **`npm:` specifiers**: Deno uses these to fetch packages from npm. Salvia automatically converts these to `https://esm.sh/...` URLs when generating the Import Map for the browser.

### `vendor_setup.ts` (The Bridge)

To make ESM modules available to the QuickJS SSR engine, Salvia uses an internal bridge file called `vendor_setup.ts`. This file imports Preact and Signals and exposes them to the global scope for QuickJS.

```typescript
// Internal vendor_setup.ts
import { h, Fragment } from "preact";
import * as preact from "preact";
import * as hooks from "preact/hooks";
import * as signals from "@preact/signals";
import { renderToString } from "preact-render-to-string";

// Expose to QuickJS global scope
(globalThis as any).Preact = preact;
(globalThis as any).PreactHooks = hooks;
(globalThis as any).PreactSignals = signals;
(globalThis as any).renderToString = renderToString;
(globalThis as any).h = h;
```

This ensures that `h` and `renderToString` are always available globally in your SSR environment without any setup.

## 5. JIT Compilation & The Sidecar

Salvia uses a "Managed Sidecar" architecture to provide instant feedback during development.

1.  **Rails** starts a background Deno process (`sidecar.ts`).
2.  When you request a page, the **DevServer** middleware intercepts requests for `.js` files.
3.  It asks the **Sidecar** to compile the corresponding `.tsx` file on-the-fly using `esbuild`.
4.  The compiled JS is served to the browser (or used for SSR).

This eliminates the need for a separate `npm run build` or `deno task watch` command. You just run `rails s` or `ruby app.rb`, and Salvia handles the rest.

## 7. The Ultimate Salvia Stack: Salvia + Turbo + Signals

The combination of Salvia, Turbo (Drive/Frames/Streams), and Preact Signals is the **definitive Salvia architecture**, balancing **"Ruby's productivity" and "SPA user experience"** with extreme efficiency.

By combining these, you can create **rich applications equivalent to or better than heavy JavaScript frameworks (like Next.js)** without using them.

Here, we explain the role of each, the chemical reaction (benefits) when combined, and concrete examples.

### 1. Roles of Each Player (What can they do?)

In this architecture, **"who is responsible for what"** is clearly divided.

#### 🌿 Salvia (The Brain)

*   **Role:** **"HTML Generation" and "Logic Execution"**
*   **Capabilities:**
    *   Fetching data from the DB using Ruby (Rails) controllers.
    *   Rendering JSX/TSX (Server Components) at high speed to create HTML.
    *   Minimizing JavaScript sent to the client (Islands only).

#### 🏎️ Turbo (The Transport)

*   **Role:** **"HTML Transport" and "Screen Updates"**
*   **Drive (Global Navigation):** Intercepts link clicks and form submissions, replacing only the `<body>` without reloading the entire page (SPA-like behavior).
*   **Frames (Partial Replacement):** Navigates only a part of the screen (e.g., modals or sidebars) independently.
*   **Streams (Differential Updates):** Adds, removes, or updates specific elements based on instructions from the server (used in WebSockets or form responses).

#### ⚡️ Preact Signals (The Nerves)

*   **Role:** **"Instant Reaction" and "State Sharing"**
*   **Capabilities:**
    *   **Micro-Interactivity:** Handles UI updates that cannot tolerate even 0.1s delay, such as updating numbers instantly upon button press or drag operations.
    *   **Shared State:** Maintains state in memory (like cart contents) even when pages switch via Turbo, sharing it across multiple Islands.

### 2. What happens when you use them all? (Benefits)

Fully utilizing these resolves the "trade-offs" in traditional development.

1.  **"No JS written" but "Moves Smoothly"**
    *   Basically, Ruby just returns HTML (Salvia).
    *   But screen transitions are blazing fast (Turbo Drive).
    *   Rich interactions happen only where needed (Signals).
    *   Result: **Low development cost, high quality** application.

2.  **Liberation from "State Management" Hell**
    *   Complex "synchronization between server data and client data" becomes unnecessary. Data is always correct on the server (HTML).
    *   The client only needs to hold "temporary UI state (Signals)", drastically reducing bugs.

3.  **Drastic Reduction in Bundle Size**
    *   No React Router, Redux, or Axios needed.
    *   Only Preact and Turbo are required. Initial display speed (LCP) becomes overwhelmingly fast.

### 3. Example: "Real-time Task Management Board" (Trello-like)

Let's see how this works with specific user operations.

#### Screen Structure

*   **Board Screen:** Lists of tasks (To Do, Doing, Done).
*   **Header:** Displays "Number of incomplete tasks".

#### Scenario and Technology Interaction

| User Operation | Backend Action | Technology | Explanation |
| :--- | :--- | :--- | :--- |
| **1. Open Page** | Server generates and displays HTML for the task list. JS is not running yet. | **Salvia** | Screen displays instantly (SSR). |
| **2. Add Task** | Type "Meeting" in the form and press Enter. | **Turbo Drive** | Sends POST request in the background without page reload. |
| **(Server Process)** | Saves task to DB and responds with **"Only the HTML for the new task"**. | **Salvia** | Lightweight response, not the whole page. |
| **3. Reflect on Screen** | Receives response and `appends` the task to the bottom of the list. | **Turbo Streams** | List updates instantly. |
| **4. Number Increases** | Detects task addition and increments "Incomplete Count" in the header by `+1`. | **Signals** | Only the number text node updates without screen redraw. |
| **5. Open Details** | Click a task to show details in a modal without screen transition. | **Turbo Frames** | Partially fetches and displays HTML from `src="/tasks/1"`. |
| **6. Drag & Drop** | Drag a task from "Doing" to "Done". | **Preact (Islands)** | **Here, JS (Signals) is the star.** Moves UI instantly without waiting for the server. |

#### Code Image

**Controller (Ruby):**

```ruby
def create
  task = Task.create(params[:task])
  
  # Return "Append" instruction and "HTML" via Turbo Stream
  # Use Salvia::SSR.render for partials
  render turbo_stream: turbo_stream.append("todo_list", html: Salvia::SSR.render("islands/TaskCard", task: task))
end
```

**TaskCard Island (TypeScript + Signals):**

```tsx
// store.ts (Shared State)
export const totalCount = signal(0);

// TaskCard.tsx
export default function TaskCard({ task }) {
  // Count up on mount (Signals)
  useEffect(() => { totalCount.value++ }, []);

  return (
    <div class="card" draggable="true">
      {task.title}
    </div>
  );
}
```

**Header Island (TypeScript + Signals):**

```tsx
// Header.tsx
export default function Header() {
  // Automatically updates when TaskCard increases/decreases
  return <div>Remaining: {totalCount}</div>;
}
```

### Conclusion

This "All-in-One" configuration is the **"Sweet Spot" (Optimal Solution) for Web Application Development**.

*   **Salvia** builds the foundation,
*   **Turbo** transports it,
*   **Signals** adds the color.

Since each focuses only on what it does best, there is no waste, and it is extremely powerful. If you are building an app from scratch, we strongly recommend starting with this "Full Set".

## 8. State-free Development

"State-free Development" refers to an experience where **"the area where developers must consciously code for 'state management' approaches zero."**

With the combination of Salvia + Turbo + Signals, the "3 types of state" that plague web app development are handled (or eliminated) as follows:

### 1. Where did they go? The "3 States"

#### ① Server State (The Data Itself)
* **Previously (SPA):** Fetch JSON from API and manage it with Redux, etc.
* **From now on (Salvia):** **Data on the server is the "truth", and HTML is its snapshot.** No need to hold or synchronize data on the client side.
    * **→ State Eliminated (Solved by Server Components)**

#### ② URL/Navigation State (Where am I?)
* **Previously (SPA):** Monitor current path and parameters with JS using `react-router`, etc.
* **From now on (Turbo Drive):** **The URL itself is the state.** Clicking a link lets Turbo automatically fetch and replace the next HTML.
    * **→ State Eliminated (Solved by Turbo)**

#### ③ UI State (Inputting, Toggling, Temporary Changes)
* **Previously (React):** Manage with `useState`, share via props drilling or Context API.
* **From now on (Signals):** **Just define `signal()` where needed and update `.value`.** It doesn't even trigger component re-rendering.
    * **→ State Management becomes "just variable assignment".**

### 2. Feeling "State-free": Shopping Cart Example

Comparing the action of "adding an item to the cart", the difference is obvious.

#### 😫 Traditional SPA (Stateful)
1.  Define Action Creator (`addToCart`).
2.  Write state update logic in Reducer (`state.items.push(...)`).
3.  Use `useDispatch` and `useSelector` in components.
4.  Dispatch when button is pressed.
5.  Call API asynchronously, and write rollback logic for failure.

#### 😌 Salvia + Turbo + Signals (State-free like)

**Pattern A: Turbo Streams (Completely Stateless)**
1.  **JS:** None.
2.  **View:** Write `<form action="/cart" method="post">`.
3.  **Server:** Add to cart and response with **"updated header HTML"**.
4.  **Turbo:** Replaces the header.
    * **→ Zero JS state management.**

**Pattern B: Signals (Optimistic UI)**
1.  **Global Signal:** `export const count = signal(0);`
2.  **Button:** `onClick={() => count.value++}` (Updates appearance instantly)
3.  **Background:** Send `fetch("/cart", ...)` in the background (Ignore result, or revert only on failure).
    * **→ State management is just one line: `count.value++`.**

### 3. The True Nature of this Architecture

This is a **return to the "Original Form of the Web (Stateless HTTP)".**

Salvia (Turbo + Signals) takes the approach of **"Returning to stateless (server-driven) basics, while using Signals—the 'strongest modern tool'—only for the 10% that absolutely needs to be rich."**

* **Tedious things (Data sync, Routing)** → **Don't do it (Leave it to Server and Turbo).**
* **Fun things (Animation, Interaction)** → **Do it with Signals.**

This is the experience worthy of being called **"State-free Development"**.

## 9. Props vs Signals: A Paradigm Shift in State Management

In Salvia, understanding data flow and choosing the right tool is crucial.

### 1. Props (The Waterfall)
**Usage**: Passing initial data from Server (Rails) to Client (Island).

*   **Direction**: Parent (Rails Controller/Page) -> Child (Island Component).
*   **Characteristic**: Immutable. Once rendered, it does not change unless the parent re-renders.
*   **Role in Salvia**: Used to display database values (ActiveRecord) in the UI.

```tsx
// Rails (Controller) -> Page -> Island
<Island name="UserProfile" props={{ name: @user.name, role: "admin" }} />
```

### 2. Signals (The Teleport)
**Usage**: Dynamic interaction on the client side.

*   **Direction**: State (Signal) <-> Component (Anywhere).
*   **Characteristic**: Reactive. When the value changes, only the places using it update instantly.
*   **Role in Salvia**: Manages changes caused by user operations (clicks, input).

```tsx
// Client Side Only
const count = signal(0);
// ...
<button onClick={() => count.value++}>{count}</button>
```

### 3. Guidelines for Use (Best Practices)

| Situation | Recommended | Reason |
| :--- | :--- | :--- |
| **Displaying data fetched from DB** | **Props** | It is a value determined by the server and does not need to change on the client. |
| **Form input values, toggle buttons** | **Signals** | Changes frequently by user operation and needs to be reflected in UI instantly. |
| **Shopping cart, notification badge** | **Signals (Global)** | To share state across multiple components (e.g., header and product list). |
| **Page transition (Link)** | **Turbo Drive** | Changing URL and fetching new HTML is simpler and more robust than managing state with JS. |

**Conclusion**:
*   **Props** for initial state,
*   **Signals** for interactivity,
*   **Turbo** for navigation.

This is Salvia's "Golden Triangle".
