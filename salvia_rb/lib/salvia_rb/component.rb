# frozen_string_literal: true

require "tilt"

module Salvia
  # View Component の基底クラス
  #
  # @example
  #   class UserCardComponent < Salvia::Component
  #     def initialize(user:)
  #       @user = user
  #     end
  #   end
  #
  #   # View
  #   <%= component "user_card", user: @user %>
  class Component
    include Salvia::Router.helpers
    include Salvia::Helpers

    def initialize(**kwargs)
      kwargs.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    # コンポーネントをレンダリングする
    #
    # @param view_context [Object] ビューコンテキスト（コントローラーなど）
    # @param block [Proc] コンテンツブロック
    # @return [String] レンダリング結果
    def render_in(view_context, &block)
      @view_context = view_context
      template_path = resolve_template_path

      unless File.exist?(template_path)
        raise Error, "Component template not found: #{template_path}"
      end

      # コンポーネント自身のインスタンス変数をローカル変数として渡す
      locals = instance_variables_hash

      template = Tilt.new(template_path)
      template.render(self, locals, &block)
    end

    # ビューコンテキストへの委譲（ヘルパーメソッドなどで使用）
    def method_missing(method, *args, &block)
      if @view_context&.respond_to?(method)
        @view_context.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      @view_context&.respond_to?(method, include_private) || super
    end

    private

    def resolve_template_path
      # UserCardComponent -> user_card_component.html.erb
      name = self.class.name.underscore
      File.join(Salvia.root, "app", "components", "#{name}.html.erb")
    end

    def instance_variables_hash
      instance_variables
        .reject { |v| v.to_s.start_with?("@_") || v == :@view_context }
        .each_with_object({}) { |v, h| h[v.to_s.delete("@").to_sym] = instance_variable_get(v) }
    end
  end
end
