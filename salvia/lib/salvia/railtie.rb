# frozen_string_literal: true

module Salvia
  class Railtie < ::Rails::Railtie
    initializer "salvia.helpers" do
      ActiveSupport.on_load(:action_view) do
        include Salvia::Helpers
      end

      ActiveSupport.on_load(:action_controller) do
        include Salvia::Helpers
      end
    end

    initializer "salvia.configure" do |app|
      # Default configuration for Rails
      Salvia.configure do |config|
        # Use Rails logger
        Salvia.logger = Rails.logger
      end
    end

    initializer "salvia.middleware" do |app|
      if Rails.env.development?
        app.middleware.use Salvia::DevServer
      end
    end
  end
end
