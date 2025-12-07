# frozen_string_literal: true

require "rack"

module Salvia
  # HTTP リクエストを処理する Rack アプリケーション
  #
  # @example config.ru
  #   require_relative "config/environment"
  #   run Salvia::Application.new
  #
  class Application
    def call(env)
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
      # ルートにマッチするか試行
      result = Router.recognize(request)

      if result
        controller_class, action, route_params = result
        controller = controller_class.new(request, response, route_params)
        controller.process(action)
      else
        # マッチするルートがない - 404
        render_not_found(response)
      end
    end

    def handle_error(error, request, response)
      if Salvia.development?
        render_development_error(error, request, response)
      else
        render_production_error(response)
      end
    end

    def render_not_found(response)
      response.status = 404
      response["Content-Type"] = "text/html; charset=utf-8"

      if Salvia.development?
        response.write(not_found_development_html)
      else
        response.write(not_found_production_html)
      end
    end

    def render_development_error(error, request, response)
      response.status = 500
      response["Content-Type"] = "text/html; charset=utf-8"
      response.write(development_error_html(error, request))
    end

    def render_production_error(response)
      response.status = 500
      response["Content-Type"] = "text/html; charset=utf-8"
      response.write(production_error_html)
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
end
