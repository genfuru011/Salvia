# frozen_string_literal: true

require "json"

module Salvia
  module Core
    class ImportMap
      def self.generate(additional_map = {})
        new.generate(additional_map)
      end

      def generate(additional_map = {})
        map = { "imports" => default_imports }
        
        # Merge imports from deno.json
        deno_imports = load_deno_imports
        map["imports"].merge!(deno_imports) if deno_imports

        # Merge islands mapping
        map["imports"].merge!(islands_mapping)

        # Merge additional map
        if additional_map["imports"]
          map["imports"].merge!(additional_map["imports"])
        end
        
        # Merge other keys
        additional_map.each do |k, v|
          next if k == "imports"
          map[k] = v
        end

        map
      end

      def load
        path = find_deno_json
        return {} unless path

        begin
          content = File.read(path)
          json = JSON.parse(content)
          json["imports"] || {}
        rescue JSON::ParserError
          {}
        end
      end

      def keys
        load.keys
      end

      private

      def default_imports
        {
          "preact" => "https://esm.sh/preact@10.19.6",
          "preact/hooks" => "https://esm.sh/preact@10.19.6/hooks",
          "preact/jsx-runtime" => "https://esm.sh/preact@10.19.6/jsx-runtime",
          "@hotwired/turbo" => "https://esm.sh/@hotwired/turbo@8.0.0",
          "sage/script" => "/salvia/assets/components/Script.tsx"
        }
      end

      def load_deno_imports
        imports = load
        return nil if imports.empty?

        # Convert npm: scheme to https://esm.sh/
        imports.transform_values do |v|
          if v.is_a?(String) && v.start_with?("npm:")
            package = v.sub("npm:", "")
            "https://esm.sh/#{package}"
          elsif v.is_a?(String) && v.start_with?("./")
            # Resolve relative paths relative to app root
            # In browser, @/ -> /salvia/app/ (dev) or /assets/app/ (prod)
            # But here we are mapping keys like "@/".
            # If v is "./app/", we want it to be "/salvia/app/" in dev.
            
            if Salvia.development?
              # Assuming v starts with "./" and points to something inside project root
              # We map it to /salvia/ + path without leading ./
              "/salvia/" + v.sub(/^\.\//, "")
            else
              # In production, assets are compiled.
              # This part is tricky without a full manifest for all files.
              # For now, let's assume standard structure.
              "/assets/" + v.sub(/^\.\//, "")
            end
          else
            v
          end
        end
      end

      def islands_mapping
        mapping = {}
        islands_path = Salvia.development? ? "/salvia/assets/islands/" : "/assets/islands/"
        
        # Base mapping for directory
        mapping["@/islands/"] = islands_path

        if Salvia.development?
          # Development: Scan islands directory and map each component
          # This ensures we can import "Counter" and get "Counter.tsx" (or whatever DevServer serves)
          # Note: DevServer should handle extension resolution or we map to specific files here.
          # Assuming DevServer handles extensionless requests or we map to .js if compiled on the fly.
          # For now, we map to the file path relative to islands_path.
          # If we use Sidecar/DevServer, it likely serves compiled JS.
          
          # Scan app/islands
          islands_dir = Salvia.config.islands_dir
          if File.directory?(islands_dir)
            Dir.glob("#{islands_dir}/**/*.{tsx,jsx,js}").each do |file|
              next if File.basename(file).start_with?("_")
              
              name = File.basename(file, ".*")
              # Map "Counter" -> "/salvia/assets/islands/Counter.tsx" (or let DevServer handle it)
              # If we map to extensionless, browser requests extensionless.
              # Let's assume DevServer handles it.
              # But to be safe and consistent with prod, we might want to map to a specific URL.
              
              # For simplicity in dev, we can just rely on @/islands/ prefix if imports use extensions.
              # But if imports are "Counter", we need a map.
              mapping["@/islands/#{name}"] = File.join(islands_path, File.basename(file))
            end
          end
        else
          # Production: Use manifest
          manifest_path = File.join(Salvia.root, "salvia/server/manifest.json")
          if File.exist?(manifest_path)
            begin
              manifest = JSON.parse(File.read(manifest_path))
              manifest.each do |name, info|
                if info["file"]
                  mapping["@/islands/#{name}"] = File.join(islands_path, info["file"])
                end
              end
            rescue JSON::ParserError
              # Ignore error
            end
          end
        end
        
        mapping
      end

      def find_deno_json
        Salvia.config.deno_config_path
      end
    end
  end
end
