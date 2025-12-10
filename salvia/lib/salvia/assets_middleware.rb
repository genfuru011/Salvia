# frozen_string_literal: true

module Salvia
  # Salvia 内部アセットを配信するミドルウェア
  # islands.js など、gem に含まれるファイルをユーザーに見せずに配信
  class AssetsMiddleware
    ASSETS = {
      "/assets/javascripts/islands.js" => {
        path: File.expand_path("../../assets/javascripts/islands.js", __dir__),
        content_type: "application/javascript"
      }
    }.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      path = env["PATH_INFO"]
      
      if (asset = ASSETS[path])
        serve_asset(asset)
      else
        @app.call(env)
      end
    end

    private

    def serve_asset(asset)
      if File.exist?(asset[:path])
        content = File.read(asset[:path])
        [
          200,
          {
            "content-type" => asset[:content_type],
            "cache-control" => "public, max-age=31536000"
          },
          [content]
        ]
      else
        [404, { "content-type" => "text/plain" }, ["Asset not found"]]
      end
    end
  end
end
