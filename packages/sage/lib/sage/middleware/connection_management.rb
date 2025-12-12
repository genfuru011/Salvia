module Sage
  module Middleware
    class ConnectionManagement
      def initialize(app)
        @app = app
      end

      def call(env)
        response = @app.call(env)
        
        # Ensure connections are returned to the pool after request
        # This is crucial for multi-threaded/async environments
        response[2] = ::Rack::BodyProxy.new(response[2]) do
          ActiveRecord::Base.connection_handler.clear_active_connections! if defined?(ActiveRecord::Base)
        end
        
        response
      rescue Exception
        ActiveRecord::Base.connection_handler.clear_active_connections! if defined?(ActiveRecord::Base)
        raise
      end
    end
  end
end
