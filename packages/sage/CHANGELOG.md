# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2025-12-12

### Added
- **Initial Release**: Introduced Sage, a modern Ruby web framework optimized for developer happiness and performance.
- **RPC Support**: Define type-safe RPC endpoints using the `rpc` keyword.
- **Client Generation**: Generate TypeScript clients for RPC endpoints with `sage generate client`.
- **Salvia Integration**: Built-in support for Salvia as the frontend engine (JSX/TSX, Islands Architecture).
- **ActiveRecord Support**: Seamless integration with ActiveRecord for database operations.
- **CLI Tools**:
  - `sage new`: Create a new Sage application with best practices.
  - `sage dev`: Start the development server with auto-reload and sidecar management.
  - `sage generate client`: Generate TypeScript definitions and clients.
- **Performance**: Enabled YJIT by default for improved runtime performance.
- **Middleware**: Included `ConnectionManagement` for proper database connection handling.
