# frozen_string_literal: true

require_relative "salvia_rb/version"
require_relative "salvia_rb/assets"

# コア依存関係
require "rack"
require "rack/session"
require "rack/protection"
require "mustermann"
require "tilt"
require "erubi"
require "active_record"
require "active_support/core_ext/string/inflections"
require "active_support/hash_with_indifferent_access"
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/salvia_rb/version.rb")
loader.inflector.inflect(
  "salvia_rb" => "Salvia",
  "cli" => "CLI"
)
loader.setup

require "logger"

# プラグインシステム
require_relative "salvia_rb/plugins/base"

module Salvia
  class Error < StandardError; end

  # 設定クラス
  class Configuration
    attr_accessor :plugins, :ssr_bundle_path, :island_inspector

    def initialize
      @plugins = []
      @ssr_bundle_path = "vendor/server/ssr_bundle.js"
      @island_inspector = nil # nil = auto (development のみ)
    end

    # Island Inspector が有効かどうか
    def island_inspector?
      return @island_inspector unless @island_inspector.nil?
      Salvia.development?
    end
  end

  class << self
    attr_accessor :root, :env, :app_loader, :logger

    def config
      @config ||= Configuration.new
    end

    def configure
      yield config if block_given?
      
      # プラグインを有効化
      config.plugins.each do |plugin_name|
        Plugins::Base.enable(plugin_name)
      end
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

