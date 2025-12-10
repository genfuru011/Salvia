# frozen_string_literal: true

module Salvia
  class Railtie < ::Rails::Railtie
    initializer "salvia.helpers" do
      ActiveSupport.on_load(:action_view) do
        include Salvia::Helpers
      end
    end

    initializer "salvia.configure" do |app|
      # Default configuration for Rails
      Salvia.configure do |config|
        config.islands_dir = Rails.root.join("app/islands")
        config.build_dir = Rails.root.join("public/assets")
        
        # Use Rails logger
        Salvia.logger = Rails.logger
      end
    end
  end
end
