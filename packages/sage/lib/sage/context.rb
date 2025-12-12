require "rack"
require "json"

module Sage
  class Context
    attr_reader :req, :res, :params, :env

    def initialize(env, params = {})
      @env = env
      @req = Rack::Request.new(env)
      @res = Rack::Response.new
      @params = params
    end

    def body(content = nil)
      if content
        @res.write(content)
      else
        @req.body.read
      end
    end

    def json(data)
      @res.headers["Content-Type"] = "application/json"
      @res.write(JSON.generate(data))
    end

    def text(content)
      @res.headers["Content-Type"] = "text/plain"
      @res.write(content)
    end

    def html(content)
      @res.headers["Content-Type"] = "text/html"
      @res.write(content)
    end

    def render(page, props = {})
      # Placeholder for Salvia integration
      html("<h1>Rendering #{page}</h1><pre>#{JSON.pretty_generate(props)}</pre>")
    end

    def redirect(path)
      @res.redirect(path)
    end

    def status(code)
      @res.status = code
    end
  end
end
