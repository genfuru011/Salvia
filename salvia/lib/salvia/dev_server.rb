module Salvia
  class DevServer
    def initialize(app)
      @app = app
    end

    def call(env)
      # Only active in development
      unless ENV["RACK_ENV"] == "development" || ENV["RAILS_ENV"] == "development"
        return @app.call(env)
      end

      request = Rack::Request.new(env)
      
      if request.path.start_with?("/salvia/assets/")
        handle_asset_request(request)
      else
        @app.call(env)
      end
    end

    private

    def handle_asset_request(request)
      # /salvia/assets/islands/Counter.js -> islands/Counter.tsx
      path_info = request.path.sub("/salvia/assets/", "")
      
      # Remove .js extension to find source
      base_name = path_info.sub(/\.js$/, "")
      
      source_path = resolve_source_path(base_name)
      
      unless source_path
        return [404, { "content-type" => "text/plain" }, ["Not Found: #{path_info}"]]
      end
      
      begin
        # Bundle for browser (ESM)
        # We externalize dependencies that should be handled by Import Map
        js_code = Salvia::Compiler.bundle(
          source_path, 
          externals: ["preact", "preact/hooks", "preact/jsx-runtime", "react", "react-dom"],
          format: "esm"
        )
        
        [200, { "content-type" => "application/javascript" }, [js_code]]
      rescue => e
        [500, { "content-type" => "text/plain" }, ["Build Error: #{e.message}"]]
      end
    end
    
    def resolve_source_path(name)
      # name is like "islands/Counter"
      
      # Check directly in salvia/app
      path = File.join(Salvia.root, "salvia/app", "#{name}.tsx")
      return path if File.exist?(path)
      
      path = File.join(Salvia.root, "salvia/app", "#{name}.jsx")
      return path if File.exist?(path)
      
      path = File.join(Salvia.root, "salvia/app", "#{name}.js")
      return path if File.exist?(path)
      
      nil
    end
  end
end
