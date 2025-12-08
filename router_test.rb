
require "mustermann"
require "active_support/core_ext/string/inflections"

module Salvia
  class Router
    Route = Struct.new(:method, :pattern, :controller, :action, keyword_init: true) do
      def match?(request_method, path)
        method.to_s.upcase == request_method && pattern.match(path)
      end

      def params_from(path)
        pattern.params(path) || {}
      end
    end

    def initialize
      @routes = []
    end

    def add_route(method, path)
      pattern = Mustermann.new(path, type: :rails)
      @routes << Route.new(method: method, pattern: pattern)
    end

    def recognize(method, path)
      @routes.each do |route|
        next unless route.match?(method, path)
        return route.params_from(path)
      end
      nil
    end
  end
end

router = Salvia::Router.new
router.add_route(:delete, "/todos/:id")

params = router.recognize("DELETE", "/todos/5")
puts "Params: #{params.inspect}"
