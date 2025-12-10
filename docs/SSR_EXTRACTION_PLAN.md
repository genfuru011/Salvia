# SSR Islands Extraction Plan

## Objective
Extract the SSR Islands architecture from Salvia into a standalone Ruby gem and repository. This will allow other Ruby frameworks (Rails, Sinatra, Hanami) to easily adopt the "Islands Architecture" with QuickJS and Deno, and simplify the core Salvia codebase.

## Proposed Library Name
**`salvia_islands`**

## Scope
The new library will handle:
1.  **SSR Engine**: QuickJS-based rendering of JavaScript components.
2.  **Build System**: Deno + esbuild integration for bundling components (SSR & Client).
3.  **View Helpers**: `island` helper for mounting components in ERB/Slim/Haml.
4.  **Hydration**: Client-side script for hydrating components.

## Architecture Changes

### Current (Salvia Internal)
- `Salvia::SSR::QuickJS`: Wraps QuickJS runtime.
- `Salvia::Helpers::Island`: Provides `island` helper.
- `bin/build_ssr.ts`: Generated into user app for building.
- `islands.js`: Client-side hydration logic.

### New (`salvia_islands` Gem)
- `SalviaIslands::Engine`: Main entry point for SSR.
- `SalviaIslands::Renderer`: Handles the QuickJS interaction.
- `SalviaIslands::Helper`: Module to be included in views.
- `SalviaIslands::CLI`: Commands for setup and building (`salvia_islands build`, `salvia_islands watch`).

## Migration Steps

### 1. Create New Repository (`salvia_islands`)
- Initialize gem structure.
- Dependencies: `quickjs`, `thor` (for CLI).

### 2. Extract Core Logic
- Move `lib/salvia_rb/ssr/quickjs.rb` -> `lib/salvia_islands/renderer/quickjs.rb`.
- Move `lib/salvia_rb/helpers/island.rb` -> `lib/salvia_islands/helper.rb`.
- Generalize the code to remove Salvia-specific dependencies (e.g., `Salvia.root`).

### 3. Extract Assets & Scripts
- Move `bin/build_ssr.ts` to `lib/salvia_islands/templates/build_ssr.ts`.
- Move hydration logic to `lib/salvia_islands/templates/hydration.js`.
- Create a CLI command `salvia_islands install` to copy these into the user's project.

### 4. Define Configuration
Allow configuration for paths and options:
```ruby
SalviaIslands.configure do |config|
  config.root = Dir.pwd
  config.islands_dir = "app/islands"
  config.build_dir = "public/assets"
end
```

### 5. Update Salvia
- Add `gem 'salvia_islands'` to Salvia's gemspec.
- Remove internal SSR logic.
- Update `Salvia::Application` to configure `SalviaIslands`.
- Update `salvia new` generator to run `salvia_islands install`.

## Benefits
- **Reusability**: Can be used with Rails (`rails-salvia_islands`?), Sinatra, etc.
- **Maintainability**: Decoupled development of the SSR engine.
- **Focus**: Salvia focuses on being a glue framework, while `salvia_islands` focuses on the specific problem of Ruby-JS integration.

## Timeline
1.  **Phase 1**: Create `salvia_islands` repo and port code.
2.  **Phase 2**: Add tests and verify standalone usage.
3.  **Phase 3**: Release `salvia_islands` v0.1.0.
4.  **Phase 4**: Refactor Salvia to use the new gem.
