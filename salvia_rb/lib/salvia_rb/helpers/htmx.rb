# frozen_string_literal: true

module Salvia
  module Helpers
    module Htmx
      # HTMX 対応のリンクタグを生成する
      #
      # @param name [String] リンクテキスト
      # @param url [String] URL
      # @param options [Hash] オプション
      # @option options [Symbol] :method HTTPメソッド (:get, :post, :put, :patch, :delete)
      # @option options [String] :target 更新対象のセレクタ (hx-target)
      # @option options [String] :swap 更新方法 (hx-swap)
      # @option options [String] :confirm 確認メッセージ (hx-confirm)
      # @option options [String] :trigger トリガーイベント (hx-trigger)
      # @return [String]
      def htmx_link_to(name, url, options = {})
        html_options = options.dup
        
        # HTMX 固有オプションの抽出
        method = html_options.delete(:method) || :get
        target = html_options.delete(:target)
        swap = html_options.delete(:swap)
        confirm = html_options.delete(:confirm)
        trigger = html_options.delete(:trigger)
        indicator = html_options.delete(:indicator)
        
        # HTMX 属性の設定
        html_options["hx-#{method}"] = url
        html_options["hx-target"] = target if target
        html_options["hx-swap"] = swap if swap
        html_options["hx-confirm"] = confirm if confirm
        html_options["hx-trigger"] = trigger if trigger
        html_options["hx-indicator"] = indicator if indicator
        
        # プログレッシブエンハンスメントのため href も設定するが、
        # method が get 以外の場合は javascript:void(0) にする手もある。
        # しかし、Salvia は HTML First なので、JS 無効環境でも動作するように
        # href=url を基本とする（ただし DELETE 等はサーバー側で対応が必要）
        link_to(name, url, html_options)
      end

      # HTMX イベントをトリガーする (レスポンスヘッダー設定)
      #
      # @param event [String] イベント名
      # @param detail [Hash] イベント詳細データ
      def htmx_trigger(event, detail = {})
        response["HX-Trigger"] = { event => detail }.to_json
      end

      # HTMX からのリクエストかどうかを判定
      #
      # @return [Boolean]
      def htmx_request?
        request.env["HTTP_HX_REQUEST"] == "true"
      end

      # HTMX 対応のフォームタグを生成する
      #
      # @param url [String] 送信先URL
      # @param options [Hash] オプション
      # @option options [Symbol] :method HTTPメソッド (:post, :put, :patch, :delete)
      # @option options [String] :target 更新対象のセレクタ (hx-target)
      # @option options [String] :swap 更新方法 (hx-swap)
      # @return [String]
      def htmx_form(url, options = {})
        html_options = options.dup
        
        method = html_options[:method] || :post
        target = html_options.delete(:target)
        swap = html_options.delete(:swap)
        indicator = html_options.delete(:indicator)
        
        # HTMX 属性の設定
        # hx-post, hx-put, hx-delete 等を設定
        # 注意: form_tag も method 属性を設定するが、HTMX は hx-* を優先する
        html_options["hx-#{method}"] = url
        html_options["hx-target"] = target if target
        html_options["hx-swap"] = swap if swap
        html_options["hx-indicator"] = indicator if indicator
        
        form_tag(url, html_options)
      end
    end
  end
end
