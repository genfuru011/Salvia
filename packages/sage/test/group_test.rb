require "test_helper"
require "rack/test"

class GroupTest < Minitest::Test
  include Rack::Test::Methods

  class TestApp < Sage::Base
    group "/api" do
      get "/version" do |ctx|
        ctx.text "v1"
      end

      group "/v2" do
        get "/version" do |ctx|
          ctx.text "v2"
        end
      end
    end
  end

  def app
    TestApp.new
  end

  def test_group_routing
    get "/api/version"
    assert last_response.ok?
    assert_equal "v1", last_response.body
  end

  def test_nested_group_routing
    get "/api/v2/version"
    assert last_response.ok?
    assert_equal "v2", last_response.body
  end
end
