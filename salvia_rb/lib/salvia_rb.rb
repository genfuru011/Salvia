# frozen_string_literal: true

require_relative "salvia_rb/version"

# コア依存関係
require "rack"
require "rack/session"
require "rack/protection"
require "mustermann"
require "tilt"
require "erubi"
require "active_record"
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/salvia_rb/version.rb")
loader.inflector.inflect(
  "salvia_rb" => "Salvia",
  "cli" => "CLI"
)
loader.setup

module Salvia
  class Error < StandardError; end

  class << self
    attr_accessor :root, :env, :app_loader

    def configure
      yield self if block_given?
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

