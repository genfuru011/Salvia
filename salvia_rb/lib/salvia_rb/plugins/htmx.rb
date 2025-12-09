# frozen_string_literal: true

require_relative "base"
require "json"

module Salvia
  module Plugins
    # HTMX プラグイン
    #
    # HTMX を使用した部分更新機能を提供します。
    # このプラグインはオプショナルであり、明示的に有効化する必要があります。
    #
    # @example 有効化
    #   Salvia.configure do |config|
    #     config.plugins << :htmx
    #   end
    #
    # @example ビューでの使用
    #   <%= htmx_link_to "詳細を見る", "/items/1", target: "#content" %>
    #
    module Htmx
      # プラグイン情報
      NAME = :htmx
      VERSION = "1.9.10"
      DESCRIPTION = "HTMX による部分更新機能"

      class << self
        # プラグインのセットアップ
        def setup
          # コントローラーにヘルパーをインクルード
          if defined?(Salvia::Controller)
            Salvia::Controller.include(Helpers)
            Salvia::Controller.include(ControllerMethods)
          end
        end

        # CDN URL
        def cdn_url
          "https://unpkg.com/htmx.org@#{VERSION}"
        end

        # スクリプトタグを生成
        def script_tag
          %(<script src="#{cdn_url}"></script>)
        end
      end

      # コントローラー用メソッド
      module ControllerMethods
        # HTMX からのリクエストかどうかを判定
        def htmx_request?
          request.env["HTTP_HX_REQUEST"] == "true"
        end

        # HTMX のブースト機能によるリクエストかどうか
        def htmx_boosted?
          request.env["HTTP_HX_BOOSTED"] == "true"
        end

        # HTMX の履歴復元リクエストかどうか
        def htmx_history_restore_request?
          request.env["HTTP_HX_HISTORY_RESTORE_REQUEST"] == "true"
        end

        # HTMX のターゲット要素のID
        def htmx_target
          request.env["HTTP_HX_TARGET"]
        end

        # HTMX のトリガー要素のID
        def htmx_trigger_id
          request.env["HTTP_HX_TRIGGER"]
        end

        # HTMX のトリガー要素の名前
        def htmx_trigger_name
          request.env["HTTP_HX_TRIGGER_NAME"]
        end

        # Smart Rendering: HTMX リクエスト時はレイアウトをスキップ
        def determine_layout(layout_option, _template)
          return false if htmx_request? && !htmx_boosted?
          super
        end
      end

      # ビューヘルパー
      module Helpers
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
        # @option options [String] :indicator ローディングインジケーターのセレクタ
        # @option options [Boolean] :push_url URL を履歴にプッシュするか (hx-push-url)
        # @return [String]
        def htmx_link_to(name, url, options = {})
          html_options = options.dup
          
          method = html_options.delete(:method) || :get
          target = html_options.delete(:target)
          swap = html_options.delete(:swap)
          confirm = html_options.delete(:confirm)
          trigger = html_options.delete(:trigger)
          indicator = html_options.delete(:indicator)
          push_url = html_options.delete(:push_url)
          
          html_options["hx-#{method}"] = url
          html_options["hx-target"] = target if target
          html_options["hx-swap"] = swap if swap
          html_options["hx-confirm"] = confirm if confirm
          html_options["hx-trigger"] = trigger if trigger
          html_options["hx-indicator"] = indicator if indicator
          html_options["hx-push-url"] = push_url.to_s if push_url != nil
          
          link_to(name, url, html_options)
        end

        # HTMX 対応のフォームタグを生成する
        #
        # @param url [String] 送信先URL
        # @param options [Hash] オプション
        # @option options [Symbol] :method HTTPメソッド (:post, :put, :patch, :delete)
        # @option options [String] :target 更新対象のセレクタ (hx-target)
        # @option options [String] :swap 更新方法 (hx-swap)
        # @option options [String] :indicator ローディングインジケーターのセレクタ
        # @return [String]
        def htmx_form(url, options = {}, &block)
          html_options = options.dup
          
          method = html_options[:method] || :post
          target = html_options.delete(:target)
          swap = html_options.delete(:swap)
          indicator = html_options.delete(:indicator)
          
          html_options["hx-#{method}"] = url
          html_options["hx-target"] = target if target
          html_options["hx-swap"] = swap if swap
          html_options["hx-indicator"] = indicator if indicator
          
          form_tag(url, html_options, &block)
        end

        # HTMX イベントをトリガーする (レスポンスヘッダー設定)
        #
        # @param event [String] イベント名
        # @param detail [Hash] イベント詳細データ
        def htmx_trigger(event, detail = {})
          response["HX-Trigger"] = { event => detail }.to_json
        end

        # 複数の HTMX イベントをトリガーする
        #
        # @param events [Hash] { event_name => detail_hash, ... }
        def htmx_trigger_multiple(events)
          response["HX-Trigger"] = events.to_json
        end

        # 遅延トリガーを設定 (settle 後に発火)
        def htmx_trigger_after_settle(event, detail = {})
          response["HX-Trigger-After-Settle"] = { event => detail }.to_json
        end

        # 遅延トリガーを設定 (swap 後に発火)
        def htmx_trigger_after_swap(event, detail = {})
          response["HX-Trigger-After-Swap"] = { event => detail }.to_json
        end

        # リダイレクト (HTMX 対応)
        def htmx_redirect(url)
          response["HX-Redirect"] = url
        end

        # ページ全体をリフレッシュ
        def htmx_refresh
          response["HX-Refresh"] = "true"
        end

        # HTMX からのリクエストかどうかを判定
        def htmx_request?
          request.env["HTTP_HX_REQUEST"] == "true"
        end
      end

      # プラグインを登録
      Base.register(NAME, self)
    end
  end
end
