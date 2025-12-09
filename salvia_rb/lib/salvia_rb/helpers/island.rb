# frozen_string_literal: true

require "json"

module Salvia
  module Helpers
    module Island
      # Island コンポーネントをレンダリングする
      #
      # SSR が有効な場合はサーバーサイドで HTML を生成し、
      # クライアントサイドでハイドレーションを行います。
      #
      # @param name [String] コンポーネント名 (例: "Counter")
      # @param props [Hash] コンポーネントに渡すプロパティ
      # @param options [Hash] オプション
      # @option options [String] :id 要素のID
      # @option options [String] :tag ラッパータグ (デフォルト: div)
      # @option options [Boolean] :ssr SSR を有効にするか (デフォルト: true)
      # @option options [Boolean] :hydrate クライアントサイドでハイドレーションするか (デフォルト: true)
      # @return [String] レンダリングされた HTML
      #
      # @example 基本的な使用法
      #   <%= island "Counter", count: 5 %>
      #
      # @example SSR を無効化 (クライアントサイドのみ)
      #   <%= island "HeavyChart", data: @data, ssr: false %>
      #
      # @example ハイドレーションを無効化 (静的 HTML のみ)
      #   <%= island "StaticCard", title: "Hello", hydrate: false %>
      #
      def island(name, props = {}, options = {})
        tag_name = options.delete(:tag) || :div
        ssr_enabled = options.fetch(:ssr, true)
        hydrate = options.fetch(:hydrate, true)
        
        # 開発モードかどうか
        development = defined?(Salvia.env) ? Salvia.env == "development" : true
        
        # SSR でコンテンツを生成
        inner_html = ""
        begin
          if ssr_enabled && defined?(Salvia::SSR) && Salvia::SSR.respond_to?(:configured?) && Salvia::SSR.configured?
            inner_html = Salvia::SSR.render(name, props)
          end
        rescue => e
          # SSR 失敗時はエラーをログに出力し、CSR にフォールバック
          if development
            inner_html = ssr_error_inline(name, e.message)
          end
        end
        
        # データ属性を構築
        data_attrs = {}
        
        if hydrate
          data_attrs[:island] = name
          data_attrs[:props] = props.to_json
        end
        
        # 開発モードではデバッグ用の属性を追加
        if development
          data_attrs[:salvia_debug] = true
          data_attrs[:salvia_component] = name
        end
        
        # HTML オプションを構築
        html_options = options.dup
        html_options.delete(:ssr)
        html_options.delete(:hydrate)
        html_options[:data] = (html_options[:data] || {}).merge(data_attrs)
        
        # 開発モードではインスペクター用のクラスを追加
        if development
          html_options[:class] = [html_options[:class], "salvia-island"].compact.join(" ")
        end
        
        tag(tag_name, html_options) { inner_html }
      end
      
      private
      
      # インラインエラー表示 (開発モード用、軽量版)
      def ssr_error_inline(name, message)
        <<~HTML
          <div style="
            background: #fee;
            border: 1px solid #fcc;
            border-radius: 4px;
            padding: 8px 12px;
            font-size: 12px;
            color: #900;
          ">
            <strong>⚠️ SSR Error:</strong> #{escape_html(name)} - #{escape_html(message)}
          </div>
        HTML
      end
      
      def escape_html(str)
        str.to_s
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub('"', "&quot;")
      end
    end
  end
end
