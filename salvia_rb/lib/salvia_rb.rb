# frozen_string_literal: true

require_relative "salvia_rb/version"
require_relative "salvia_rb/assets"
require_relative "salvia_rb/assets_middleware"

# コア依存関係
require "rack"
require "rack/session"
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
  "cli" => "CLI",
  "csrf" => "CSRF",
  "ssr" => "SSR"
)
loader.setup

require "logger"

# プラグインシステム
require_relative "salvia_rb/plugins/base"

module Salvia
  class Error < StandardError; end

  # 設定クラス
  # すべての設定にはデフォルト値があり、書かなくても動く
  class Configuration
    attr_accessor :plugins, :ssr_bundle_path, :island_inspector,
                  :database_url, :session_secret, :session_key,
                  :default_server, :autoload_paths, :log_level,
                  :csrf_enabled, :static_files_enabled

    def initialize
      # SSR Islands
      @plugins = []
      @ssr_bundle_path = "vendor/server/ssr_bundle.js"
      @island_inspector = nil  # nil = auto (development のみ)

      # データベース (nil = database.yml または規約ベース)
      @database_url = nil

      # セッション (nil = 自動生成)
      @session_secret = nil
      @session_key = nil  # nil = "_#{app_name}_session"

      # サーバー (nil = 環境に応じて自動選択)
      @default_server = nil  # dev: puma, prod: falcon

      # Autoload (追加パス)
      @autoload_paths = []

      # ログ (nil = 環境に応じて自動)
      @log_level = nil  # dev: debug, prod: info

      # セキュリティ
      @csrf_enabled = true
      @static_files_enabled = true
    end

    # Island Inspector が有効かどうか
    def island_inspector?
      return @island_inspector unless @island_inspector.nil?
      Salvia.development?
    end

    # セッションキーを取得 (デフォルト: アプリ名から生成)
    def session_key_value
      @session_key || "_#{app_name}_session"
    end

    # セッションシークレットを取得 (デフォルト: 環境変数または自動生成)
    def session_secret_value
      @session_secret || ENV["SESSION_SECRET"] || SecureRandom.hex(64)
    end

    # ログレベルを取得
    def log_level_value
      @log_level || (Salvia.development? ? :debug : :info)
    end

    # デフォルトサーバーを取得
    def default_server_value
      @default_server || (Salvia.production? ? :falcon : :puma)
    end

    private

    def app_name
      File.basename(Salvia.root).gsub(/[^a-zA-Z0-9_]/, "_")
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

    # ワンライナー起動 (Sinatra 風)
    #
    # @example 基本的な使い方
    #   Salvia.run!
    #
    # @example ポート指定
    #   Salvia.run! port: 3000
    #
    # @example サーバー指定
    #   Salvia.run! server: :falcon
    #
    # デフォルト動作:
    #   - development: Puma (スレッドベース、macOS 互換)
    #   - production: Falcon (async、高パフォーマンス)
    #
    def run!(options = {})
      port = options.fetch(:port, 9292)
      host = options.fetch(:host, "0.0.0.0")
      server = options.fetch(:server) { config.default_server_value }

      app = Application.new

      puts "🌿 Salvia starting..."
      puts "   Environment: #{env}"
      puts "   Server: #{server}"
      puts "   Listening: http://#{host}:#{port}"
      puts ""

      case server
      when :falcon
        run_falcon(app, host, port)
      when :puma
        run_puma(app, host, port)
      else
        run_rack(app, host, port, server)
      end
    end

    private

    def default_server
      config.default_server_value
    end

    def falcon_available?
      require "falcon"
      true
    rescue LoadError
      false
    end

    def puma_available?
      require "puma"
      true
    rescue LoadError
      false
    end

    def run_falcon(app, host, port)
      require "falcon"
      require "async"

      # Falcon の Rack アダプター
      endpoint = Async::HTTP::Endpoint.parse("http://#{host}:#{port}")

      Async do
        server = Falcon::Server.new(
          Falcon::Server.middleware(app),
          endpoint
        )
        server.run
      end
    rescue LoadError
      warn "⚠️  Falcon not found. Install with: gem install falcon"
      warn "   Falling back to Puma..."
      run_puma(app, host, port)
    end

    def run_puma(app, host, port)
      require "rack/handler/puma"
      Rack::Handler::Puma.run(app, Host: host, Port: port, Verbose: false)
    rescue LoadError
      warn "⚠️  Puma not found. Install with: gem install puma"
      run_rack(app, host, port, :webrick)
    end

    def run_rack(app, host, port, server)
      Rack::Handler.get(server.to_s).run(app, Host: host, Port: port)
    rescue LoadError
      warn "⚠️  #{server} not found. Using WEBrick..."
      Rack::Handler::WEBrick.run(app, Host: host, Port: port)
    end
  end
end

