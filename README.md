# Sage & Salvia Monorepo 🌿

This repository houses the development of **Sage** (Backend Framework) and **Salvia** (Frontend Engine).

## Documentation

- [Reference Guide](REFERENCE.md) - Detailed documentation on routing, RPC, frontend integration, and more.
- [Syntax Guide](SYNTAX.md) - Quick reference for Sage syntax.

## Packages

*   **[Sage](packages/sage)**: A lightweight, high-performance REST framework for Ruby, built on Falcon.
*   **[Salvia](packages/salvia)**: A next-generation SSR engine for Ruby on Rails (and Sage), replacing ERB with JSX/TSX.

## Development

This is a monorepo managed with Bundler.

```bash
# Install dependencies for all packages
$ bundle install
```

## Directory Structure

```
packages/
├── sage/    # The Sage Framework
└── salvia/  # The Salvia View Engine
```
