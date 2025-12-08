# frozen_string_literal: true

module Salvia
  # シンプルな Flash メッセージ機能
  #
  # 次のリクエストまで保持されるメッセージを管理します。
  # session[:_flash] を使用してデータを保持します。
  #
  # @example
  #   flash[:notice] = "保存しました"
  #   flash.now[:alert] = "エラーが発生しました"
  class Flash
    def initialize(session)
      @session = session
      @session[:_flash] ||= {}
      @now = @session[:_flash].dup
      @session[:_flash].clear
    end

    # 次のリクエストまで保持するメッセージを設定/取得
    def [](key)
      @now[key] || @session[:_flash][key]
    end

    def []=(key, value)
      @session[:_flash][key] = value
    end

    # 現在のリクエストでのみ有効なメッセージを設定
    def now
      @now
    end

    # Flash メッセージが空かどうか
    def empty?
      @now.empty? && @session[:_flash].empty?
    end

    def to_h
      @now.merge(@session[:_flash])
    end
  end
end
