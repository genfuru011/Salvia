require "async"
require "falcon"
require "falcon/server"

module Sage
  class Server
    def initialize(app)
      @app = app
    end

    def start(port: 3000)
      # Wrap the app using Falcon's middleware helper
      app = Falcon::Server.middleware(@app)
      endpoint = Async::HTTP::Endpoint.parse("http://0.0.0.0:#{port}")

      Async do
        server = Falcon::Server.new(app, endpoint)
        puts "🌿 Sage is running on http://0.0.0.0:#{port}"
        server.run
      end
    end
  end
end
