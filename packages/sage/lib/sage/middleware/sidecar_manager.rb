module Sage
  module Middleware
    class SidecarManager
      def initialize(app)
        @app = app
      end

      def call(env)
        Sage::Sidecar.ensure_running!
        @app.call(env)
      end
    end
  end
end
