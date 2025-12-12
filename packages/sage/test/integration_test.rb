require "test_helper"
require "rack/test"

class IntegrationTest < Minitest::Test
  include Rack::Test::Methods

  class TestApp < Sage::Base
    get "/" do |ctx|
      ctx.text "Hello World"
    end

    get "/json" do |ctx|
      ctx.json({ status: "ok" })
    end

    get "/users/:id" do |ctx, id|
      ctx.text "User #{id}"
    end
  end

  def app
    TestApp.new
  end

  def test_hello
    get "/"
    assert last_response.ok?
    assert_equal "Hello World", last_response.body
    assert_equal "text/plain", last_response.content_type
  end

  def test_json
    get "/json"
    assert last_response.ok?
    assert_equal '{"status":"ok"}', last_response.body
    assert_equal "application/json", last_response.content_type
  end

  def test_params
    get "/users/123"
    assert last_response.ok?
    assert_equal "User 123", last_response.body
  end
end
