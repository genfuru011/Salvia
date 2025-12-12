require "test_helper"
require "rack/test"
require "salvia"

class SalviaIntegrationTest < Minitest::Test
  include Rack::Test::Methods

  class TestApp < Sage::Base
    get "/" do |ctx|
      ctx.render "Home", title: "Hello Salvia"
    end
  end

  def app
    TestApp.new
  end

  def setup
    # Mock Salvia::SSR
    Salvia::SSR.singleton_class.class_eval do
      define_method(:render_page) do |name, props, options|
        "<html><body><h1>#{name}</h1><p>#{props[:title]}</p></body></html>"
      end
    end
  end

  def test_render_salvia_page
    get "/"
    assert last_response.ok?
    assert_equal "text/html", last_response.content_type
    assert_includes last_response.body, "<h1>Home</h1>"
    assert_includes last_response.body, "<p>Hello Salvia</p>"
  end
end
