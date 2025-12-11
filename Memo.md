# Salvia Implementation Memo

### 5. Internalization of `build.ts` (Zero Config)

*   **Goal:** Remove `build.ts` from the user's project to simplify the file structure and enforce "Zero Config".
*   **Implementation:**
    *   Moved `build.ts` logic to `salvia/assets/scripts/build.ts` (internal).
    *   Updated `salvia install` to **not** copy `build.ts`.
    *   Updated `salvia install` to copy `deno.json` to `salvia/deno.json` (so users can manage imports).
    *   Updated `salvia build` CLI command to run the internal `build.ts`.
    *   Updated internal `build.ts` to prioritize the user's `salvia/deno.json` if it exists, allowing for custom imports.
*   **Verification:**
    *   Removed `build.ts` from `examples/rails_api_app`.
    *   Ran internal build script successfully.
    *   Verified SSR bundle and client islands were generated.

### 6. Preact-only Architecture

*   **Goal:** Enforce Preact as the sole frontend framework to simplify the stack and leverage Signals.
*   **Implementation:**
    *   Updated `deno.json` templates to use `preact` and `@preact/signals` directly (via `esm.sh`).
    *   Updated `vendor_setup.ts` to export Preact and Signals.
    *   Updated `sidecar.ts` to handle Preact global externals.
    *   Updated documentation (`DESIGN.md`) to reflect this decision.

### 7. Unified Import Management

*   **Goal:** Use `deno.json` as the Single Source of Truth (SSOT) for imports.
*   **Implementation:**
    *   `deno.json` defines imports (e.g. `preact`, `@/`).
    *   `build.ts` (esbuild) uses `deno.json` for resolution.
    *   `sidecar.ts` (JIT) uses `deno.json` for resolution.
    *   `ssr` helper injects `importmap` generated from `deno.json` into the HTML.
