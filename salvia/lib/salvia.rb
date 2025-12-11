# frozen_string_literal: true

require_relative "salvia/version"

require "rack"
require "zeitwerk"
require "logger"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/salvia/version.rb")
loader.inflector.inflect(
  "salvia" => "Salvia",
  "cli" => "CLI",
  "ssr" => "SSR"
)
loader.setup

module Salvia
  class Error < StandardError; end

  class Configuration
    attr_accessor :ssr_bundle_path, :island_inspector, :islands_dir, :build_dir, :deno_config_path, :root

    def initialize
      @root = Dir.pwd
      @ssr_bundle_path = "salvia/server/ssr_bundle.js"
      @islands_dir = "salvia/app/islands"
      @build_dir = "public/assets"
      @deno_config_path = "salvia/deno.json"
      @island_inspector = nil
    end

    def island_inspector?
      return @island_inspector unless @island_inspector.nil?
      Salvia.development?
    end
  end

  class << self
    attr_accessor :root, :env, :logger

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def config
      @config ||= Configuration.new
    end

    def configure
      yield config if block_given?
      
      # Initialize SSR engine
      if defined?(Salvia::SSR)
        Salvia::SSR.configure(
          bundle_path: config.ssr_bundle_path,
          development: development?
        )
      end
    end

    def root
      config.root
    end

    def env
      @env ||= ENV.fetch("RACK_ENV", "development")
    end

    def development?
      env == "development"
    end

    def production?
      env == "production"
    end

    def test?
      env == "test"
    end
  end
end

require "salvia/railtie" if defined?(Rails)
