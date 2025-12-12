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
  "ssr" => "SSR",
  "quickjs" => "QuickJS"
)
loader.setup

module Salvia
  # Alias Core classes for backward compatibility
  Error = Core::Error
  Configuration = Core::Configuration

  class << self
    attr_accessor :root, :env, :logger

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def config
      @config ||= Core::Configuration.new
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
      @env ||= ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development"
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
