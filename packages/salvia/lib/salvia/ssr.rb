# frozen_string_literal: true

module Salvia
  module SSR
    class Error < Salvia::Error; end
    class EngineNotFoundError < Error; end
    class RenderError < Error; end

    # SSR アダプターの基底クラス
    class BaseAdapter
      attr_reader :options

      def initialize(options = {})
        @options = options
        @initialized = false
      end

      # エンジンを初期化
      def setup!
        raise NotImplementedError, "#{self.class}#setup! must be implemented"
      end

      # コンポーネントをレンダリング
      # @param component_name [String] コンポーネント名
      # @param props [Hash] プロパティ
      # @return [String] レンダリングされた HTML
      def render(component_name, props = {})
        raise NotImplementedError, "#{self.class}#render must be implemented"
      end

      # コンポーネントを登録
      # @param name [String] コンポーネント名
      # @param code [String] コンポーネントの JS コード
      def register_component(name, code)
        raise NotImplementedError, "#{self.class}#register_component must be implemented"
      end

      # エンジンをシャットダウン
      def shutdown!
        # オーバーライド可能
      end

      def initialized?
        @initialized
      end

      # エンジン名
      def engine_name
        raise NotImplementedError
      end

      protected

      def mark_initialized!
        @initialized = true
      end
    end

    class << self
      attr_accessor :current_adapter
      attr_accessor :last_build_error

      # SSR エンジンを設定
      # @param options [Hash] エンジンオプション
      # @option options [Symbol] :engine エンジン名 (:quickjs)
      # @option options [String] :bundle_path SSR バンドルのパス
      # @option options [Boolean] :development 開発モード
      def configure(options = {})
        engine = options.fetch(:engine, :quickjs)
        
        case engine
        when :quickjs
          require_relative "ssr/quickjs"
          @current_adapter = QuickJS.new(options)
        else
          raise EngineNotFoundError, "Unknown SSR engine: #{engine}"
        end

        @current_adapter.setup!
        @current_adapter
      end

      # コンポーネントをレンダリング
      # @param component_name [String] コンポーネント名
      # @param props [Hash] プロパティ
      # @return [String] レンダリングされた HTML
      def render(component_name, props = {})
        ensure_configured!
        current_adapter.render(component_name, props)
      end

      # ページコンポーネントをレンダリング (Import Map 注入 + DOCTYPE)
      # @param component_name [String] コンポーネント名
      # @param props [Hash] プロパティ
      # @param options [Hash] オプション
      # @return [String] 完全な HTML 文字列
      def render_page(component_name, props = {}, options = {})
        html = render(component_name, props)
        
        # <head> がある場合、Import Map を自動注入
        # Import Map は他のモジュールスクリプトより前に定義する必要があるため、
        # <head> の直後に注入する
        if html.include?("<head>")
          map = Salvia::Core::ImportMap.generate
          import_map_html = <<~HTML
            <script type="importmap">
              #{map.to_json}
            </script>
          HTML
          html = html.sub("<head>", "<head>#{import_map_html}")
        elsif html.include?("</head>")
          # <head> タグが見つからない場合のフォールバック (非推奨)
          map = Salvia::Core::ImportMap.generate
          import_map_html = <<~HTML
            <script type="importmap">
              #{map.to_json}
            </script>
          HTML
          html = html.sub("</head>", "#{import_map_html}</head>")
        end
        
        if options.fetch(:doctype, true)
          html = "<!DOCTYPE html>\n" + html
        end
        
        html
      end

      # コンポーネントを登録
      def register_component(name, code)
        ensure_configured!
        current_adapter.register_component(name, code)
      end
      
      # バンドルをリロード (開発モード用)
      def reload!
        return unless configured?
        current_adapter.reload_bundle! if current_adapter.respond_to?(:reload_bundle!)
      end
      
      # ビルドエラーを設定
      def set_build_error(error)
        @last_build_error = error
        current_adapter.last_build_error = error if current_adapter&.respond_to?(:last_build_error=)
      end
      
      # ビルドエラーを取得
      def build_error
        @last_build_error || (current_adapter&.respond_to?(:last_build_error) ? current_adapter.last_build_error : nil)
      end

      # ビルドエラーがあるか確認
      def build_error?
        !build_error.nil?
      end
      
      # ビルドエラーをクリア
      def clear_build_error
        @last_build_error = nil
        current_adapter.last_build_error = nil if current_adapter&.respond_to?(:last_build_error=)
      end

      # シャットダウン
      def shutdown!
        current_adapter&.shutdown!
        @current_adapter = nil
      end

      # 設定済みか確認
      def configured?
        !current_adapter.nil? && current_adapter.initialized?
      end

      private

      def ensure_configured!
        return if configured?
        
        # Auto-configure using defaults from Salvia.config
        # This handles cases where Salvia.configure wasn't explicitly called
        # or called before SSR module was fully loaded
        configure(
          bundle_path: Salvia.config.ssr_bundle_path,
          development: Salvia.development?
        )
      rescue => e
        # If auto-configuration fails, we raise the original error to avoid masking it
        raise Error, "SSR not configured and auto-configuration failed: #{e.message}. Call Salvia::SSR.configure explicitly."
      end
    end
  end
end
