require "test_helper"

class SageTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Sage::VERSION
  end
end
