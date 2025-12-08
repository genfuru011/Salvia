# frozen_string_literal: true

require "json"

module Salvia
  module Helpers
    module Island
      # Island コンポーネントをレンダリングする
      #
      # @param name [String] コンポーネント名 (例: "Counter")
      # @param props [Hash] コンポーネントに渡すプロパティ
      # @param options [Hash] オプション
      # @option options [String] :id 要素のID
      # @option options [String] :tag ラッパータグ (デフォルト: div)
      # @return [String]
      def island(name, props = {}, options = {})
        tag_name = options[:tag] || :div
        html_options = options.dup
        html_options.delete(:tag)
        
        html_options[:data] ||= {}
        html_options[:data][:island] = name
        html_options[:data][:props] = props.to_json
        
        tag(tag_name, html_options) { "" }
      end
    end
  end
end
