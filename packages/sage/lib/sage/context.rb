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
      html_content = Sage::Sidecar.rpc("render_page", {
        page: page,
        props: props
      })
      html(html_content)
    end

    def component(path, props = {})
      Sage::Sidecar.rpc("render_component", {
        path: path,
        props: props
      })
    end

    def turbo_stream(action, target, component_path = nil, html: nil, **props)
      content = html || (component_path ? component(component_path, props) : "")
      
      stream = <<~HTML
        <turbo-stream action="#{action}" target="#{target}">
          <template>#{content}</template>
        </turbo-stream>
      HTML
      
      @res.headers["Content-Type"] = "text/vnd.turbo-stream.html"
      body(stream)
    end

    def redirect(path)
      @res.redirect(path)
    end

    def status(code)
      @res.status = code
    end
  end
end
