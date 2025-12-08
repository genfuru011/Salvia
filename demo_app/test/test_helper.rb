ENV["RACK_ENV"] = "test"
require_relative "../config/environment"
require "minitest/autorun"
require "salvia_rb/test"

class Minitest::Test
  include Salvia::Test::ControllerHelper
end
