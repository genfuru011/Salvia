# frozen_string_literal: true

require_relative "salvia_rb/version"
require_relative "salvia_rb/assets"
require_relative "salvia_rb/import_map"

# コア依存関係
require "rack"
require "rack/session"
require "rack/protection"
require "mustermann"
require "tilt"
require "erubi"
require "active_record"
require "active_support/core_ext/string/inflections"
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/salvia_rb/version.rb")
loader.inflector.inflect(
  "salvia_rb" => "Salvia",
  "cli" => "CLI"
)
loader.setup

require "logger"

module Salvia
  class Error < StandardError; end

  class << self
    attr_accessor :root, :env, :app_loader, :logger

    def importmap
      @importmap ||= ImportMap.new
    end

    def configure
      yield self if block_given?
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def load_config
      config_file = File.join(root, "config", "environments", "#{env}.rb")
      require config_file if File.exist?(config_file)
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

