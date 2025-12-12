require "test_helper"
require "rack/test"

class ResourceTest < Minitest::Test
  include Rack::Test::Methods

  class PostsResource < Sage::Resource
    # Rails-style
    def index
      json({ action: "index" })
    end

    def show(id)
      json({ action: "show", id: id })
    end

    # Sinatra-style
    get "/archive" do |ctx|
      ctx.text "Archive Page"
    end

    # RPC
    rpc :like do |id|
      { liked: true, id: id }
    end
  end

  class TestApp < Sage::Base
    mount "/posts", PostsResource
  end

  def app
    TestApp.new
  end

  def test_rails_style_index
    get "/posts"
    assert last_response.ok?
    assert_equal '{"action":"index"}', last_response.body
  end

  def test_rails_style_show
    get "/posts/123"
    assert last_response.ok?
    assert_equal '{"action":"show","id":"123"}', last_response.body
  end

  def test_sinatra_style_custom_route
    get "/posts/archive"
    assert last_response.ok?
    assert_equal "Archive Page", last_response.body
  end

  def test_rpc_route
    post "/posts/like", { id: 999 }
    assert last_response.ok?
    assert_equal "application/json", last_response.content_type
    # Note: In a real app, params would be parsed from body, but here we pass them to handler
    # The current implementation of rpc wrapper passes *args.
    # Let's check how the router passes params.
  end
end
