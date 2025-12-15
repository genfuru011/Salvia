require "async"
require "async/http/endpoint"

module Sage
  module Middleware
    class HMR
      def initialize(app)
        @app = app
        @clients = []
      end

      def call(env)
        request = Rack::Request.new(env)

        if request.path == "/_sage/reload"
          return handle_sse(env)
        elsif request.path == "/_sage/notify" && request.post?
          return handle_notify(env)
        end

        @app.call(env)
      end

      private

      def handle_sse(env)
        body = Async::HTTP::Body::Writable.new
        
        @clients << body
        
        # Send initial retry interval
        body.write("retry: 1000\n\n")

        # Keep connection open
        # In Falcon/Async, returning this body keeps the stream open until body.close is called
        [200, { "content-type" => "text/event-stream", "cache-control" => "no-cache" }, body]
      end

      def handle_notify(env)
        # Restart Deno Sidecar to clear cache
        Sage::Sidecar.restart!

        # Notify all connected clients
        disconnected = []
        
        @clients.each do |client|
          begin
            client.write("data: reload\n\n")
          rescue
            disconnected << client
          end
        end
        
        # Cleanup disconnected clients
        disconnected.each { |c| @clients.delete(c) }
        
        [200, { "content-type" => "text/plain" }, ["OK"]]
      end
    end
  end
end
