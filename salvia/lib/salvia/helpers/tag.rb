# frozen_string_literal: true

module Salvia
  module Helpers
    module Tag
      # HTML タグを生成する
      #
      # @param name [Symbol, String] タグ名
      # @param options [Hash] 属性
      # @param block [Proc] コンテンツブロック
      # @return [String] HTML 文字列
      def tag(name, options = {}, &block)
        html_options = options.map do |key, value|
          next if value.nil?
          
          if value.is_a?(Hash) && key == :data
            value.map { |k, v| %(data-#{k.to_s.gsub("_", "-")}="#{escape_html(v)}") }.join(" ")
          elsif value == true
            key
          else
            %(#{key}="#{escape_html(value)}")
          end
        end.compact.join(" ")
        
        html_options = " " + html_options unless html_options.empty?
        
        if block_given?
          content = block.call
          "<#{name}#{html_options}>#{content}</#{name}>"
        else
          "<#{name}#{html_options} />"
        end
      end

      private

      def escape_html(str)
        str.to_s
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub('"', "&quot;")
          .gsub("'", "&#39;")
      end
    end
  end
end
