# frozen_string_literal: true

require_relative "lib/salvia_rb/version"

Gem::Specification.new do |spec|
  spec.name = "salvia_rb"
  spec.version = Salvia::VERSION
  spec.authors = ["Salvia Contributors"]
  spec.email = []

  spec.summary = "A small, understandable Ruby MVC framework"
  spec.description = "A simple and clear Ruby web framework with ERB, SSR Islands, Tailwind, and ActiveRecord. No Node.js required."
  spec.homepage = "https://github.com/salvia-rb/salvia"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    Dir["{lib,exe,templates}/**/*", "LICENSE.txt", "README.md"]
  end
  spec.bindir = "exe"
  spec.executables = ["salvia"]
  spec.require_paths = ["lib"]

  # Core dependencies
  spec.add_dependency "rack", "~> 3.0"
  spec.add_dependency "rackup", "~> 2.0"
  spec.add_dependency "rack-session", "~> 2.0"
  spec.add_dependency "rack-protection", "~> 3.0"
  spec.add_dependency "rack-test", "~> 2.0"

  spec.add_dependency "puma", "~> 6.0"
  spec.add_dependency "mustermann", "~> 3.0"
  spec.add_dependency "mustermann-contrib", "~> 3.0"
  spec.add_dependency "tilt", "~> 2.0"
  spec.add_dependency "erubi", "~> 1.12"

  # Database
  spec.add_dependency "activerecord", "~> 7.0"

  # CLI
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tty-prompt", "~> 0.23"

  # Auto-loading
  spec.add_dependency "zeitwerk", "~> 2.6"

  # CSS (Node.js free)
  spec.add_dependency "tailwindcss-ruby", "~> 3.4"

  # SSR Engines (optional - users choose one)
  # QuickJS Native: gem 'quickjs'
  # QuickJS Wasm:   gem 'wasmtime'
  # Deno:           install deno CLI

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "sqlite3", "~> 1.6"
  spec.add_development_dependency "quickjs", "~> 0.1"
end
