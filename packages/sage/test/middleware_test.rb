require "test_helper"
require "rack/test"

class MiddlewareTest < Minitest::Test
  include Rack::Test::Methods

  class HeaderMiddleware
    def initialize(app, header_name, header_value)
      @app = app
      @header_name = header_name
      @header_value = header_value
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers[@header_name] = @header_value
      [status, headers, body]
    end
  end

  class TestApp < Sage::Base
    use HeaderMiddleware, "X-Sage-Test", "Passed"

    get "/" do |ctx|
      ctx.text "Hello Middleware"
    end
  end

  def app
    TestApp.new
  end

  def test_middleware_execution
    get "/"
    assert last_response.ok?
    assert_equal "Hello Middleware", last_response.body
    assert_equal "Passed", last_response.headers["X-Sage-Test"]
  end
end
