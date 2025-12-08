# frozen_string_literal: true

require "rack/test"

module Salvia
  module Test
    module ControllerHelper
      include Rack::Test::Methods

      def app
        Salvia::Application.new
      end

      # セッションを有効にするための設定
      def session
        last_request.env["rack.session"]
      end
    end
  end
end
