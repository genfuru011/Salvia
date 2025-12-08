# frozen_string_literal: true

module Salvia
  module Helpers
    module Component
      # View Component をレンダリングする
      #
      # @param name [String, Symbol] コンポーネント名 (例: "user_card")
      # @param kwargs [Hash] コンポーネントに渡す引数
      # @param block [Proc] コンテンツブロック
      # @return [String] レンダリング結果
      def component(name, **kwargs, &block)
        # "user_card" -> "UserCardComponent"
        class_name = "#{name.to_s.camelize}Component"
        
        begin
          klass = Object.const_get(class_name)
        rescue NameError
          raise NameError, "Component class not found: #{class_name} (expected app/components/#{name}_component.rb)"
        end

        unless klass < Salvia::Component
          raise ArgumentError, "#{class_name} must inherit from Salvia::Component"
        end

        instance = klass.new(**kwargs)
        instance.render_in(self, &block)
      end
    end
  end
end
