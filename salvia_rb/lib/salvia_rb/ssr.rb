# frozen_string_literal: true

module Salvia
  module SSR
    class Error < StandardError; end
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
      # @param engine [Symbol] :hybrid (推奨), :quickjs_native, :quickjs_wasm, :deno
      # @param options [Hash] エンジン固有のオプション
      def configure(engine = :hybrid, options = {})
        adapter_class = case engine.to_sym
                        when :hybrid, :quickjs_hybrid
                          require_relative "ssr/adapters/quickjs_hybrid"
                          Adapters::QuickJSNative
                        when :quickjs, :quickjs_native
                          require_relative "ssr/adapters/quickjs_native"
                          Adapters::QuickJSNative
                        when :quickjs_wasm, :wasm
                          require_relative "ssr/adapters/quickjs_wasm"
                          Adapters::QuickJSWasm
                        when :deno
                          require_relative "ssr/adapters/deno"
                          Adapters::Deno
                        else
                          raise EngineNotFoundError, "Unknown SSR engine: #{engine}"
                        end

        @current_adapter = adapter_class.new(options)
        @current_adapter.setup!
        @current_adapter
      end

      # コンポーネントをレンダリング
      # @param component_name [String] コンポーネント名
      # @param props [Hash] プロパティ
      # @return [String] レンダリングされた HTML
      def render(component_name, props = {})
        raise Error, "SSR not configured. Call Salvia::SSR.configure first." unless current_adapter
        current_adapter.render(component_name, props)
      end

      # コンポーネントを登録
      def register_component(name, code)
        raise Error, "SSR not configured. Call Salvia::SSR.configure first." unless current_adapter
        current_adapter.register_component(name, code)
      end
      
      # バンドルをリロード (開発モード用)
      def reload!
        return unless current_adapter
        current_adapter.reload_bundle! if current_adapter.respond_to?(:reload_bundle!)
      end
      
      # ビルドエラーを設定
      def set_build_error(error)
        @last_build_error = error
        current_adapter.last_build_error = error if current_adapter&.respond_to?(:last_build_error=)
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
    end
  end
end
