# frozen_string_literal: true

module Salvia
  module Helpers
    module Tag
      # HTMLタグを生成する
      #
      # @param name [String, Symbol] タグ名
      # @param options [Hash] 属性
      # @param block [Proc] コンテンツブロック
      # @return [String]
      def tag(name, options = {}, &block)
        attributes = options.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
        attributes = " " + attributes unless attributes.empty?

        if block_given?
          content = block.call
          "<#{name}#{attributes}>#{content}</#{name}>"
        else
          "<#{name}#{attributes}>"
        end
      end

      # リンクタグを生成する
      #
      # @param name [String] リンクテキスト
      # @param url [String] URL
      # @param options [Hash] 属性
      # @return [String]
      def link_to(name, url, options = {})
        tag(:a, options.merge(href: url)) { name }
      end
    end
  end
end
