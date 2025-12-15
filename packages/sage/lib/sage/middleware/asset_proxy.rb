require "async/http/endpoint"
require "async/http/client"
require "io/endpoint/unix_endpoint"

module Sage
  module Middleware
    class AssetProxy
      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless env["PATH_INFO"].start_with?("/assets/")

        Sage::Sidecar.ensure_running!

        endpoint = Async::HTTP::Endpoint.parse("http://sage-sidecar#{env['PATH_INFO']}")
        endpoint.endpoint = IO::Endpoint.unix(Sage::Sidecar.socket_path)
        
        client = Async::HTTP::Client.new(endpoint)
        
        # Forward the request
        response = client.get(endpoint.path)
        
        # Read body
        body = response.read
        
        [response.status, response.headers.to_h, [body]]
      ensure
        client&.close
      end
    end
  end
end
