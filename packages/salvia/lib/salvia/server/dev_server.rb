module Salvia
  module Server
    class DevServer
    def initialize(app)
      @app = app
    end

    def call(env)
      # Only active in development
      # Prefer Rails.env if available, otherwise check ENV
      is_dev = if defined?(Rails) && Rails.respond_to?(:env)
                 Rails.env.development?
               else
                 ENV["RACK_ENV"] == "development" || ENV["RAILS_ENV"] == "development"
               end

      return @app.call(env) unless is_dev

      request = Rack::Request.new(env)
      
      if request.path.start_with?("/salvia/assets/")
        handle_asset_request(request)
      elsif request.path == "/assets/javascripts/islands.js"
        # Handle islands.js specifically for development convenience
        # This matches the path used in Home.tsx template and ensures it works without build
        serve_islands_js
      else
        @app.call(env)
      end
    end

    private

    def handle_asset_request(request)
      # /salvia/assets/islands/Counter.js -> islands/Counter.tsx
      path_info = request.path.sub("/salvia/assets/", "")
      
      # Special handling for islands.js (Client Entry)
      if path_info == "javascripts/islands.js"
        return serve_islands_js
      end

      # Special handling for internal components
      if path_info.start_with?("components/")
        return serve_internal_component(path_info)
      end
      
      # Remove extension to find source (supports .js, .tsx, .ts, .jsx)
      # Also handle requests without extension (from import map resolution)
      base_name = path_info.sub(/\.(js|tsx|ts|jsx)$/, "")
      
      source_path = resolve_source_path(base_name)
      
      unless source_path
        return [404, { "content-type" => "text/plain" }, ["Not Found: #{path_info}"]]
      end
      
      begin
        # Bundle for browser (ESM)
        # We externalize dependencies that should be handled by Import Map
        externals = Salvia::Core::ImportMap.new.keys
        
        js_code = Salvia::Compiler.bundle(
          source_path, 
          externals: externals.uniq,
          format: "esm"
        )
        
        [200, { "content-type" => "application/javascript" }, [js_code]]
      rescue => e
        [500, { "content-type" => "text/plain" }, ["Build Error: #{e.message}"]]
      end
    end
    
    def resolve_source_path(name)
      Salvia::Core::PathResolver.resolve(name)
    end

    def serve_islands_js
      # 1. Check public assets (Build output or user override)
      public_path = File.join(Salvia.root, "public/assets/javascripts/islands.js")
      if File.exist?(public_path)
        return [200, { "content-type" => "application/javascript" }, [File.read(public_path)]]
      end

      # 2. Check user's source (salvia/assets/javascripts/islands.js) - Legacy/Custom path
      user_path = File.join(Salvia.root, "salvia/assets/javascripts/islands.js")
      if File.exist?(user_path)
        return [200, { "content-type" => "application/javascript" }, [File.read(user_path)]]
      end
      
      # 3. Fallback to internal islands.js
      internal_path = File.expand_path("../../../assets/javascripts/islands.js", __dir__)
      if File.exist?(internal_path)
        return [200, { "content-type" => "application/javascript" }, [File.read(internal_path)]]
      end
      
      [404, { "content-type" => "text/plain" }, ["islands.js not found"]]
    end

    def serve_internal_component(path_info)
      # components/Script.tsx -> packages/salvia/lib/salvia/server/components/Script.tsx
      component_name = path_info.sub("components/", "")
      
      # Fix path resolution: __dir__ is lib/salvia/server, so ../components is lib/salvia/components
      # But we created it in lib/salvia/server/components
      internal_path = File.expand_path("components/#{component_name}", __dir__)
      
      unless File.exist?(internal_path)
        return [404, { "content-type" => "text/plain" }, ["Component not found: #{component_name} (Path: #{internal_path})"]]
      end

      begin
        externals = Salvia::Core::ImportMap.new.keys
        js_code = Salvia::Compiler.bundle(
          internal_path, 
          externals: externals.uniq,
          format: "esm"
        )
        [200, { "content-type" => "application/javascript" }, [js_code]]
      rescue => e
        [500, { "content-type" => "text/plain" }, ["Build Error: #{e.message}"]]
      end
    end
    end
  end
end
