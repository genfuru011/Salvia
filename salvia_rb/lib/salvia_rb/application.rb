# frozen_string_literal: true

require "rack"
require "rack/session"
require "securerandom"

module Salvia
  # HTTP リクエストを処理する Rack アプリケーション
  #
  # ゼロコンフィグで動作可能。config.ru は以下だけで OK:
  #
  # @example 最小構成 (config.ru)
  #   require "salvia_rb"
  #   run Salvia::Application.new
  #
  # @example カスタム構成
  #   require "salvia_rb"
  #   Salvia.root = File.expand_path(__dir__)
  #   Salvia.configure { |c| c.ssr_bundle_path = "custom/path.js" }
  #   run Salvia::Application.new
  #
  class Application
    def initialize
      auto_setup!
    end

    def call(env)
      # アプリをミドルウェアスタックでラップして呼び出し
      @stack.call(env)
    end

    private

    # ゼロコンフィグ自動セットアップ
    def auto_setup!
      detect_root!
      setup_environment!
      setup_database!
      setup_autoloader!
      load_routes!
      build_middleware_stack!
    end

    # アプリケーションルートを自動検出
    def detect_root!
      return if Salvia.root && Salvia.root != Dir.pwd

      # config.ru からの相対パスを検出
      caller_locations.each do |loc|
        if loc.path.end_with?("config.ru")
          Salvia.root = File.dirname(File.expand_path(loc.path))
          return
        end
      end

      # フォールバック: カレントディレクトリ
      Salvia.root ||= Dir.pwd
    end

    # 環境設定を読み込み
    def setup_environment!
      # 環境ごとの設定ファイルがあれば読み込む
      Salvia.load_config

      # デフォルトロガー設定
      setup_default_logger!
    end

    def setup_default_logger!
      return if Salvia.instance_variable_get(:@logger)

      if Salvia.development?
        Salvia.logger = Logger.new($stdout)
        Salvia.logger.level = Logger::DEBUG
      else
        log_dir = File.join(Salvia.root, "log")
        FileUtils.mkdir_p(log_dir)
        Salvia.logger = Logger.new(File.join(log_dir, "#{Salvia.env}.log"))
        Salvia.logger.level = Logger::INFO
      end
    end

    # データベースを自動セットアップ（規約ベース）
    def setup_database!
      return unless database_available?

      if database_config_exists?
        Salvia::Database.setup!
      else
        setup_default_database!
      end
    rescue StandardError => e
      Salvia.logger.warn "データベース接続をスキップ: #{e.message}"
    end

    def database_available?
      defined?(ActiveRecord) && Dir.exist?(File.join(Salvia.root, "db"))
    end

    def database_config_exists?
      File.exist?(File.join(Salvia.root, "config", "database.yml"))
    end

    # 規約ベースのデフォルトデータベース設定
    def setup_default_database!
      db_path = File.join(Salvia.root, "db", "#{Salvia.env}.sqlite3")
      FileUtils.mkdir_p(File.dirname(db_path))

      ActiveRecord::Base.establish_connection(
        adapter: "sqlite3",
        database: db_path
      )

      ActiveRecord::Base.logger = Logger.new($stdout) if Salvia.development?
    end

    # Zeitwerk autoloader を自動セットアップ
    def setup_autoloader!
      return if Salvia.app_loader

      loader = Zeitwerk::Loader.new

      # app 以下の標準ディレクトリを自動登録
      %w[controllers models components].each do |dir|
        path = File.join(Salvia.root, "app", dir)
        loader.push_dir(path) if Dir.exist?(path)
      end

      loader.enable_reloading if Salvia.development?
      loader.setup
      Salvia.app_loader = loader
    end

    # ルートファイルを読み込み
    def load_routes!
      routes_file = File.join(Salvia.root, "config", "routes.rb")

      if File.exist?(routes_file)
        require routes_file
      else
        # routes.rb がない場合は規約ベースでルート生成
        setup_conventional_routes!
      end
    end

    # 規約ベースの自動ルーティング
    def setup_conventional_routes!
      Salvia::Router.draw do
        # コントローラーファイルから自動推論
        controllers_dir = File.join(Salvia.root, "app", "controllers")
        return unless Dir.exist?(controllers_dir)

        Dir.glob(File.join(controllers_dir, "*_controller.rb")).each do |file|
          controller_name = File.basename(file, "_controller.rb")
          next if controller_name == "application"

          if controller_name == "home"
            root to: "home#index"
          else
            get "/#{controller_name}", to: "#{controller_name}#index"
            get "/#{controller_name}/:id", to: "#{controller_name}#show"
          end
        end
      end
    end

    # ミドルウェアスタックを構築
    def build_middleware_stack!
      app = RackApp.new

      # 内側から外側へ積み上げ
      @stack = app
      @stack = build_logging_middleware(@stack)
      @stack = build_csrf_middleware(@stack)
      @stack = build_session_middleware(@stack)
      @stack = build_static_middleware(@stack)
    end

    # 静的ファイル配信ミドルウェア
    def build_static_middleware(app)
      return app unless Salvia.config.static_files_enabled

      # Salvia 内部アセット
      app = Salvia::AssetsMiddleware.new(app)

      # public/assets
      public_dir = File.join(Salvia.root, "public")
      if Dir.exist?(public_dir)
        app = Rack::Static.new(app,
          urls: ["/assets"],
          root: public_dir,
          header_rules: [[:all, { "cache-control" => "public, max-age=31536000" }]]
        )
      end

      # vendor/client (Islands クライアント)
      client_dir = File.join(Salvia.root, "vendor", "client")
      if Dir.exist?(client_dir)
        app = ClientAssetsMiddleware.new(app, client_dir)
      end

      app
    end

    # セッションミドルウェア
    def build_session_middleware(app)
      Rack::Session::Cookie.new(app,
        key: Salvia.config.session_key_value,
        secret: Salvia.config.session_secret_value,
        same_site: :lax,
        secure: Salvia.production?
      )
    end

    # CSRF 保護ミドルウェア
    def build_csrf_middleware(app)
      return app unless Salvia.config.csrf_enabled
      return app unless defined?(Salvia::CSRF::Protection)
      Salvia::CSRF::Protection.new(app)
    end

    # ロギングミドルウェア
    def build_logging_middleware(app)
      Rack::CommonLogger.new(app, Salvia.logger)
    end

    # 内部 Rack アプリ（リクエスト処理）
    class RackApp
      def call(env)
        if Salvia.development? && Salvia.app_loader
          Salvia.app_loader.reload
        end

        request = Rack::Request.new(env)
        response = Rack::Response.new

        begin
          handle_request(request, response)
        rescue StandardError => e
          handle_error(e, request, response)
        end

        response.finish
      end

      private

      def handle_request(request, response)
        result = Router.recognize(request)

        if result
          controller_class, action, route_params = result
          controller = controller_class.new(request, response, route_params)
          controller.process(action)
        else
          render_not_found(response)
        end
      end

      def handle_error(error, request, response)
        Salvia.logger.error "#{error.class}: #{error.message}"
        Salvia.logger.error error.backtrace&.first(10)&.join("\n")

        if Salvia.development?
          render_development_error(error, request, response)
        else
          render_production_error(response)
        end
      end

      def render_not_found(response)
        response.status = 404
        response["content-type"] = "text/html; charset=utf-8"

        if Salvia.development?
          response.write(not_found_development_html)
        else
          response.write(public_file_content("404.html") || not_found_production_html)
        end
      end

      def render_development_error(error, request, response)
        response.status = 500
        response["content-type"] = "text/html; charset=utf-8"
        response.write(development_error_html(error, request))
      end

      def render_production_error(response)
        response.status = 500
        response["content-type"] = "text/html; charset=utf-8"
        response.write(public_file_content("500.html") || production_error_html)
      end

      def public_file_content(filename)
        path = File.join(Salvia.root, "public", filename)
        File.read(path) if File.exist?(path)
      end

      def not_found_development_html
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>404 Not Found - Salvia</title>
            <style>
              body { font-family: system-ui, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
              h1 { color: #6A5ACD; }
              pre { background: #f5f5f5; padding: 15px; border-radius: 8px; overflow-x: auto; }
              .routes { margin-top: 20px; }
              .route { padding: 8px; border-bottom: 1px solid #eee; font-family: monospace; }
            </style>
          </head>
          <body>
            <h1>🌿 404 Not Found</h1>
            <p>このリクエストにマッチするルートがありません。</p>
            <div class="routes">
              <h3>登録されているルート:</h3>
              #{routes_list_html}
            </div>
          </body>
          </html>
        HTML
      end

      def routes_list_html
        Router.instance.routes.map do |route|
          %(<div class="route">#{route.method.to_s.upcase.ljust(7)} #{route.pattern} → #{route.controller}##{route.action}</div>)
        end.join("\n")
      end

      def not_found_production_html
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head><title>404 Not Found</title></head>
          <body>
            <h1>404 Not Found</h1>
            <p>お探しのページは見つかりませんでした。</p>
          </body>
          </html>
        HTML
      end

      def development_error_html(error, request)
        backtrace = error.backtrace&.first(20)&.map { |line| "<div>#{Rack::Utils.escape_html(line)}</div>" }&.join || ""

        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Error - Salvia</title>
            <style>
              body { font-family: system-ui, sans-serif; max-width: 1000px; margin: 50px auto; padding: 20px; }
              h1 { color: #dc2626; }
              .error-class { color: #6A5ACD; font-size: 1.2em; }
              .error-message { background: #fef2f2; border: 1px solid #fecaca; padding: 15px; border-radius: 8px; margin: 15px 0; }
              .backtrace { background: #1e1e1e; color: #d4d4d4; padding: 15px; border-radius: 8px; font-family: monospace; font-size: 13px; overflow-x: auto; }
              .backtrace div { padding: 2px 0; }
              .request-info { margin-top: 20px; background: #f5f5f5; padding: 15px; border-radius: 8px; }
              .request-info dt { font-weight: bold; margin-top: 10px; }
              .request-info dd { margin-left: 0; font-family: monospace; }
            </style>
          </head>
          <body>
            <h1>🔥 #{Rack::Utils.escape_html(error.class.name)}</h1>
            <div class="error-message">#{Rack::Utils.escape_html(error.message)}</div>

            <h3>バックトレース</h3>
            <div class="backtrace">#{backtrace}</div>

            <div class="request-info">
              <h3>リクエスト情報</h3>
              <dl>
                <dt>メソッド</dt><dd>#{request.request_method}</dd>
                <dt>パス</dt><dd>#{Rack::Utils.escape_html(request.path_info)}</dd>
                <dt>パラメータ</dt><dd>#{Rack::Utils.escape_html(request.params.inspect)}</dd>
              </dl>
            </div>
          </body>
          </html>
        HTML
      end

      def production_error_html
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head><title>500 Internal Server Error</title></head>
          <body>
            <h1>500 Internal Server Error</h1>
            <p>エラーが発生しました。しばらくしてからもう一度お試しください。</p>
          </body>
          </html>
        HTML
      end
    end

    # Islands クライアントアセット配信ミドルウェア
    class ClientAssetsMiddleware
      def initialize(app, client_dir)
        @app = app
        @file_server = Rack::Files.new(client_dir)
      end

      def call(env)
        path = env["PATH_INFO"]
        if path.start_with?("/client/")
          env = env.dup
          env["PATH_INFO"] = path.sub("/client", "")
          status, headers, body = @file_server.call(env)
          headers["content-type"] = "application/javascript" if status == 200
          [status, headers, body]
        else
          @app.call(env)
        end
      end
    end
  end
end
