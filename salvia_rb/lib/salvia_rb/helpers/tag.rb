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

      # フォーム開始タグを生成する
      #
      # @param url [String] アクションURL
      # @param options [Hash] オプション
      # @option options [Symbol] :method HTTPメソッド (デフォルト: :post)
      # @return [String]
      def form_tag(url, options = {})
        html_options = options.dup
        method = html_options.delete(:method) || :post
        
        # method が get/post 以外の場合、_method パラメータを使用
        real_method = method.to_s.downcase
        form_method = %w[get post].include?(real_method) ? real_method : "post"
        
        html_options[:action] = url
        html_options[:method] = form_method

        # 属性を文字列化
        attributes = html_options.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
        attributes = " " + attributes unless attributes.empty?

        html = ["<form#{attributes}>"]
        
        # CSRF トークン (GET 以外)
        if real_method != "get" && respond_to?(:csrf_token) && csrf_token
          html << tag(:input, type: "hidden", name: "authenticity_token", value: csrf_token)
        end

        # Method Override
        if real_method != form_method
          html << tag(:input, type: "hidden", name: "_method", value: real_method)
        end

        html.join("\n")
      end

      # フォーム終了タグを生成する
      #
      # @return [String]
      def form_close
        "</form>"
      end
    end
  end
end
