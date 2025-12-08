require_relative "../test_helper"

class HomeControllerTest < Minitest::Test
  def test_index
    get "/"
    assert last_response.ok?
    assert_includes last_response.body, "Salvia"
  end
end
