# Salvia "True HTML First" Implementation Plan

This plan focuses on realizing the "Full JSX/TSX Architecture" where ERB is eliminated and the view layer is fully handled by Salvia (JSX/TSX).

## Phase 1: CLI & Directory Structure Updates
**Goal**: Ensure `salvia install` generates the correct "True HTML First" structure.

- [x] **Update CLI (`lib/salvia/cli.rb`)**
    - [x] Generate `salvia/app/pages/` directory (for Server Components).
    - [x] Generate `salvia/app/components/` directory (for Shared Components).
    - [x] Generate `salvia/app/islands/` directory (for Client Islands).
    - [x] Update `deno.json` template to include `app/` alias.
    - [x] Update `build.ts` template to support the new structure (already partially done, need to verify).

## Phase 2: "Page" Rendering Support
**Goal**: Enable rendering full pages from Controllers without ERB.

- [x] **Verify `island` helper for Pages**
    - [x] Can we use `helpers.island("pages/Home")`? (Used `island("Home")` with build script adjustment).
    - [x] Does it correctly handle the full HTML structure (`<html>`, `<head>`, `<body>`)?
- [ ] **Implement `render_salvia` (or similar) helper**
    - [ ] A wrapper around `render html: ...` to make it cleaner in Controllers.
    - [ ] Example: `render_salvia "pages/Home", props: { ... }`

## Phase 3: Full JSX Example Application
**Goal**: Create a proof-of-concept application that uses NO ERB files.

- [x] **Create `examples/full_jsx_app`**
    - [x] Sinatra or Rails API mode.
    - [x] `app/pages/Home.tsx` (Server Component).
    - [x] `app/components/Layout.tsx` (Shared).
    - [x] `app/islands/Counter.tsx` (Client).
- [x] **Verify "0kb JS" for Server Components**
    - [x] Ensure `Home.tsx` code is NOT included in the client bundle.

## Phase 4: Documentation & Final Polish
- [ ] **Update README.md** with the new "Full JSX" usage guide.
- [ ] **Finalize WisdomforSalvia.md**.

## Phase 5: JIT Architecture (The "Vite-like" Experience)
**Goal**: Eliminate the need for manual `deno task watch` and achieve JIT compilation.

- [x] **Step 1: Managed Sidecar Optimization (The "Dream" Features)**
    - [x] Implement `Salvia::Sidecar` (Process Manager)
    - [x] Implement `Salvia::Compiler` (Interface) & `DenoSidecar` (Adapter)
    - [x] Create `salvia/sidecar.ts` (The Deno Script)
    - [x] Integrate with Rails/Sinatra (Middleware/Controller)
    - [x] **Integrate Deno Ecosystem**:
        - [x] Implement `deno fmt` support (in Sidecar).
        - [x] Implement `deno check` for background type checking.
- [x] **Production Strategy**
    - [x] Implement `salvia build` for pre-compilation (Verified with new structure).
    - [x] Hybrid runtime (pre-built files in production).
