require_relative "lib/sage/version"

Gem::Specification.new do |spec|
  spec.name = "sage"
  spec.version = Sage::VERSION
  spec.authors = ["Hiroto"]
  spec.email = ["hiroto@example.com"]

  spec.summary = "A lightweight REST framework for Ruby, designed for Salvia."
  spec.description = "Sage is a high-performance API server framework built on Falcon, designed to work seamlessly with Salvia."
  spec.homepage = "https://github.com/hiroto/salvia"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/hiroto/salvia"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile templates/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "falcon"
  spec.add_dependency "async"
  spec.add_dependency "rack"
  spec.add_dependency "thor"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "minitest"
end
