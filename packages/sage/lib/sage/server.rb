require "async"
require "falcon"
require "falcon/server"
require "async/http/endpoint"

module Sage
  class Server
    def initialize(app)
      @app = app
    end

    def start(port: 3000)
      # Wrap the app using Falcon's middleware helper
      app = @app
      
      # Serve static files if public directory exists
      if Dir.exist?("public")
        puts "🌿 Serving static files from public/"
        require "rack/static"
        # Serve everything in public/assets under /assets
        app = Rack::Static.new(app, urls: ["/assets"], root: "public")
      else
        puts "⚠️  public/ directory not found, static files disabled"
      end

      # Add Salvia DevServer if available (for on-the-fly compilation)
      if defined?(Salvia::Server::DevServer) && (ENV["RACK_ENV"] == "development" || ENV["RAILS_ENV"] == "development")
        puts "🌿 Salvia DevServer enabled"
        app = Salvia::Server::DevServer.new(app)
      end

      app = Falcon::Server.middleware(app)
      endpoint = Async::HTTP::Endpoint.parse("http://0.0.0.0:#{port}")

      Async do
        server = Falcon::Server.new(app, endpoint)
        puts "🌿 Sage is running on http://0.0.0.0:#{port}"
        puts "🔥 YJIT Enabled" if defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
        server.run
      end
    end
  end
end
