# frozen_string_literal: true

require_relative "salvia_rb/version"

# コア依存関係
require "rack"
require "mustermann"
require "tilt"
require "erubi"
require "active_record"
require "zeitwerk"

module Salvia
  class Error < StandardError; end

  class << self
    attr_accessor :root, :env

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

# Salvia コンポーネントを読み込み
require_relative "salvia_rb/router"
require_relative "salvia_rb/controller"
require_relative "salvia_rb/application"
require_relative "salvia_rb/database"
