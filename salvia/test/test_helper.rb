# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../lib/salvia"

module SalviaTestHelper
  def reset_salvia!
    Salvia.instance_variable_set(:@root, nil)
    Salvia.instance_variable_set(:@env, nil)
    Salvia.instance_variable_set(:@app_loader, nil)
    Salvia.instance_variable_set(:@logger, nil)
    Salvia.instance_variable_set(:@config, nil)
    Salvia::Router.reset!
  end
end

class Minitest::Test
  include SalviaTestHelper
end
