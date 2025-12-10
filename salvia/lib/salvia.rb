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
    attr_accessor :ssr_bundle_path, :island_inspector, :islands_dir, :build_dir

    def initialize
      @ssr_bundle_path = "vendor/server/ssr_bundle.js"
      @islands_dir = "app/islands"
      @build_dir = "public/assets"
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
    end

    def root
      @root ||= Dir.pwd
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
