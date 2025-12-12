# frozen_string_literal: true

require_relative "lib/salvia/version"

Gem::Specification.new do |spec|
  spec.name = "salvia"
  spec.version = Salvia::VERSION
  spec.authors = ["Hiroto Furugen"]
  spec.email = ["hiro_genfuru0119@icloud.com"]

  spec.summary = "Ruby Islands Architecture Engine"
  spec.description = "A standalone SSR engine for Ruby, bringing Islands Architecture to any Rack application without Node.js."
  spec.homepage = "https://github.com/genfuru011/Salvia"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/genfuru011/Salvia/tree/main/salvia"
  spec.metadata["documentation_uri"] = "https://github.com/genfuru011/Salvia/tree/main/docs"
  spec.metadata["bug_tracker_uri"] = "https://github.com/genfuru011/Salvia/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = ["salvia"]
  spec.require_paths = ["lib"]

  # Core dependencies
  spec.add_dependency "rack", "~> 3.0"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "zeitwerk", "~> 2.6"
  spec.add_dependency "quickjs", "~> 0.1"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
