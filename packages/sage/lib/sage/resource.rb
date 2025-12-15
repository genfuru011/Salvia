module Sage
  class Resource
    class << self
      attr_reader :routes

      def get(path, &block)
        add_route("GET", path, &block)
      end

      def post(path, &block)
        add_route("POST", path, &block)
      end

      def rpc(name, params: {}, &block)
        # Store RPC definition for introspection
        @rpcs ||= {}
        @rpcs[name] = { params: params }

        # RPC is always POST /:name
        # It wraps the response in JSON automatically
        path = "/#{name}"
        
        wrapper = proc do |ctx|
          # Parse JSON body
          body_params = begin
            if ctx.req.body
              JSON.parse(ctx.req.body.read, symbolize_names: true)
            else
              {}
            end
          rescue JSON::ParserError
            {}
          end
          
          # Extract arguments based on params definition
          args = params.keys.map { |k| body_params[k] }
          
          # Call the block with ctx and args
          # TODO: Better argument passing (keyword args vs positional)
          result = block.call(ctx, *args)
          ctx.json(result)
        end

        add_route("POST", path, &wrapper)
      end

      def rpcs
        @rpcs || {}
      end

      # Inspect methods defined in the subclass to automatically map them
      def map_methods!
        instance_methods(false).each do |method_name|
          # Skip internal methods or helpers if any
          next if method_name.to_s.start_with?("_")

          # Map 'index' to GET /
          if method_name == :index
            add_route("GET", "/", &method_handler(method_name))
          
          # Map 'show' to GET /:id
          elsif method_name == :show
            add_route("GET", "/:id", &method_handler(method_name))
          
          # Map 'create' to POST /
          elsif method_name == :create
            add_route("POST", "/", &method_handler(method_name))
          
          # Map 'update' to PATCH /:id
          elsif method_name == :update
            add_route("PATCH", "/:id", &method_handler(method_name))
          
          # Map 'destroy' to DELETE /:id
          elsif method_name == :destroy
            add_route("DELETE", "/:id", &method_handler(method_name))
          end
        end
      end

      private

      def add_route(method, path, &block)
        @routes ||= []
        @routes << { method: method, path: path, handler: block }
      end

      def method_handler(method_name)
        proc do |ctx, *args|
          # Create an instance of the resource and call the method
          resource = new(ctx)
          resource.send(method_name, *args)
        end
      end
    end

    attr_reader :ctx

    def initialize(ctx)
      @ctx = ctx
    end

    # Delegate helper methods to context
    def render(page, props = {})
      ctx.render(page, props)
    end

    def json(data)
      ctx.json(data)
    end
  end
end
