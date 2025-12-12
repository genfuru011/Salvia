# frozen_string_literal: true

module Salvia
  module Adapters
    class Sage
      def self.setup
        # Include helpers in Sage::Context
        ::Sage::Context.include(Salvia::Helpers)

        # Override render method to use Salvia
        ::Sage::Context.class_eval do
          def render(page, props = {}, options = {})
            # Use salvia_page helper from Salvia::Helpers::Island
            # salvia_page returns a string, so we wrap it in html() response
            html(salvia_page(page, props, options))
          end

          def salvia_component(name, props = {})
            Salvia::Helpers::Island.salvia_component(name, props)
          end
        end
      end
    end
  end
end
