# frozen_string_literal: true

require "json"

module Salvia
  module Helpers
    module Island
      # Island マニフェストをキャッシュ
      @manifest = nil
      @manifest_mtime = nil
      
      class << self
        # マニフェストを読み込む
        def load_manifest
          manifest_path = File.join(Dir.pwd, "salvia/server/manifest.json")
          return {} unless File.exist?(manifest_path)
          
          mtime = File.mtime(manifest_path)
          if @manifest.nil? || @manifest_mtime != mtime
            @manifest = JSON.parse(File.read(manifest_path))
            @manifest_mtime = mtime
          end
          @manifest
        rescue => e
          {}
        end
        
        # Island が client only かどうか
        def client_only?(name)
          manifest = load_manifest
          manifest.dig(name, "clientOnly") == true
        end

        # Island が server only かどうか
        def server_only?(name)
          manifest = load_manifest
          manifest.dig(name, "serverOnly") == true
        end
      end
      
      # Import Map タグを生成する
      def salvia_import_map(additional_map = {})
        map = Salvia::Core::ImportMap.generate(additional_map)
        
        html = <<~HTML
          <script type="importmap">
            #{map.to_json}
          </script>
        HTML
        
        html.respond_to?(:html_safe) ? html.html_safe : html
      end

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
      # @option options [Boolean] :ssr SSR を有効にするか (デフォルト: auto)
      # @option options [Boolean] :hydrate クライアントサイドでハイドレーションするか (デフォルト: true)
      # @return [String] レンダリングされた HTML
      #
      # @example 基本的な使用法
      #   <%= island "Counter", count: 5 %>
      #
      # @example SSR を明示的に無効化
      #   <%= island "HeavyChart", data: @data, ssr: false %>
      #
      # @example ハイドレーションを無効化 (静的 HTML のみ)
      #   <%= island "StaticCard", title: "Hello", hydrate: false %>
      #
      def island(name, props = {}, options = {})
        tag_name = options.delete(:tag) || :div
        
        # デフォルトの hydrate 値を決定
        # serverOnly (app/pages) の場合はデフォルトで false
        default_hydrate = !Island.server_only?(name)
        hydrate = options.fetch(:hydrate, default_hydrate)
        
        # SSR 有効/無効の判定
        # 1. options[:ssr] が明示的に指定されていればそれを使う
        # 2. マニフェストで "client only" ならば SSR 無効
        # 3. デフォルトは SSR 有効
        ssr_enabled = if options.key?(:ssr)
          options[:ssr]
        else
          !Island.client_only?(name)
        end
        
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
        
        result = build_tag(tag_name, html_options) { inner_html }
        result.respond_to?(:html_safe) ? result.html_safe : result
      end
      
      # ページコンポーネントをレンダリングする (Full JSX Architecture用)
      #
      # <!DOCTYPE html> を付与し、ルート要素としてレンダリングします。
      # また、<head> タグが存在する場合、自動的に Import Map を注入します。
      #
      # @param name [String] ページコンポーネント名 (例: "pages/Home")
      # @param props [Hash] プロパティ
      # @param options [Hash] オプション
      # @option options [Boolean] :doctype <!DOCTYPE html> を付与するか (デフォルト: true)
      # @return [String] 完全な HTML 文字列
      def ssr(name, props = {}, options = {})
        # SSR で HTML を生成
        html = Salvia::SSR.render(name, props)
        
        # <head> がある場合、Import Map を自動注入
        if html.include?("</head>")
          import_map_html = salvia_import_map
          html = html.sub("</head>", "#{import_map_html}</head>")
        end
        
        result = html
        if options.fetch(:doctype, true)
          result = "<!DOCTYPE html>\n" + result
        end
        
        result.respond_to?(:html_safe) ? result.html_safe : result
      end
      
      # 後方互換性のため
      alias_method :salvia_page, :ssr

      private
      
      def build_tag(name, options)
        content = block_given? ? yield : ""
        attrs = options.map do |key, value|
          if key == :data && value.is_a?(Hash)
            value.map { |k, v| " data-#{k.to_s.gsub('_', '-')}=\"#{escape_html(v)}\"" }.join
          else
            " #{key}=\"#{escape_html(value)}\""
          end
        end.join
        
        "<#{name}#{attrs}>#{content}</#{name}>"
      end
      
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
