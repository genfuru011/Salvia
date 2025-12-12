require_relative "router"
require_relative "context"

module Sage
  class Base
    def self.router
      @router ||= Router.new
    end

    def self.use(middleware, *args, &block)
      router.use(middleware, *args, &block)
    end

    def self.get(path, &block)
      router.add("GET", path, &block)
    end

    def self.use(middleware, *args, &block)
      router.use(middleware, *args, &block)
    end

    def self.group(prefix, &block)
      # Create a proxy object to capture routes defined in the block
      proxy = GroupProxy.new(router, prefix)
      proxy.instance_eval(&block)
    end

    class GroupProxy
      def initialize(router, prefix)
        @router = router
        @prefix = prefix
      end

      def use(middleware, *args, &block)
        # TODO: Scoped middleware support
        # For now, we just add it to the router, but we need to scope it
        # This requires Router to support path-based middleware or nested routers
        @router.use(middleware, *args, &block)
      end

      def get(path, &block)
        add_route("GET", path, &block)
      end

      def post(path, &block)
        add_route("POST", path, &block)
      end

      def mount(path, resource)
        # Combine group prefix and mount path
        full_prefix = [@prefix, path].join("/").gsub(/\/+/, "/")
        full_prefix = full_prefix.chomp("/") if full_prefix.length > 1
        
        Sage::Base.mount(full_prefix, resource)
      end

      def group(path, &block)
        full_prefix = [@prefix, path].join("/").gsub(/\/+/, "/")
        full_prefix = full_prefix.chomp("/") if full_prefix.length > 1
        
        proxy = GroupProxy.new(@router, full_prefix)
        proxy.instance_eval(&block)
      end

      private

      def add_route(method, path, &block)
        full_path = [@prefix, path].join("/").gsub(/\/+/, "/")
        full_path = full_path.chomp("/") if full_path.length > 1
        @router.add(method, full_path, &block)
      end
    end

    def self.mount(prefix, resource)
      # Track mounted resources for generator
      @mounted_resources ||= {}
      @mounted_resources[prefix] = resource

      # Auto-map methods if not already done
      resource.map_methods!

      resource.routes.each do |route|
        # Combine prefix and path, ensuring single slash
        full_path = [prefix, route[:path]].join("/").gsub(/\/+/, "/")
        # Remove trailing slash if it's not root
        full_path = full_path.chomp("/") if full_path.length > 1
        
        router.add(route[:method], full_path, &route[:handler])
      end
    end

    def self.mounted_resources
      @mounted_resources || {}
    end

    # Rack interface
    def call(env)
      req_method = env["REQUEST_METHOD"]
      path_info = env["PATH_INFO"]

      handler, params, middlewares = self.class.router.match(req_method, path_info)

      if handler
        # Build middleware stack for this request
        app = proc do |env|
          ctx = Context.new(env, params)
          
          # Execute handler
          if handler.arity == 1
            handler.call(ctx)
          else
            handler.call(ctx, *params.values)
          end
          
          ctx.res.finish
        end

        # Wrap app with middlewares
        # middlewares is array of [Class, args, block]
        middlewares.reverse_each do |m_class, m_args, m_block|
          app = m_class.new(app, *m_args, &m_block)
        end

        app.call(env)
      else
        [404, { "content-type" => "text/plain" }, ["Not Found"]]
      end
    end
  end
end
