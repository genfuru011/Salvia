module Sage
  class Router
    def initialize
      @routes = {
        "GET" => [],
        "POST" => [],
        "PUT" => [],
        "DELETE" => [],
        "PATCH" => []
      }
      @middlewares = []
    end

    def use(middleware, *args, &block)
      @middlewares << [middleware, args, block]
    end

    def add(method, path, &block)
      # Capture current middlewares for this route
      route_middlewares = @middlewares.dup

      # Convert /users/:id to regex ^/users/([^/]+)$
      keys = []
      pattern = path.gsub(/:(\w+)/) do
        keys << $1
        "([^/]+)"
      end
      regex = Regexp.new("^#{pattern}$")

      @routes[method] << {
        regex: regex,
        keys: keys,
        handler: block,
        middlewares: route_middlewares
      }
    end

    def match(method, path)
      return nil unless @routes[method]

      @routes[method].each do |route|
        if match_data = route[:regex].match(path)
          params = {}
          route[:keys].each_with_index do |key, index|
            params[key] = match_data[index + 1]
          end
          return route[:handler], params, route[:middlewares]
        end
      end
      nil
    end
  end
end
