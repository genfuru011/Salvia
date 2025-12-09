# frozen_string_literal: true

# HTMX ヘルパー - 後方互換性のためのラッパー
#
# このファイルは後方互換性のために残されています。
# 新しいプロジェクトでは `Salvia::Plugins::Htmx` を使用してください。
#
# @example 新しい方法（推奨）
#   Salvia.configure do |config|
#     config.plugins << :htmx
#   end
#
# @example 古い方法（非推奨）
#   include Salvia::Helpers::Htmx

require_relative "../plugins/htmx"

module Salvia
  module Helpers
    # HTMX ヘルパーモジュール
    # 
    # @deprecated Use `Salvia::Plugins::Htmx` instead.
    #   This module is kept for backward compatibility.
    module Htmx
      include Salvia::Plugins::Htmx::Helpers

      def self.included(base)
        warn "[DEPRECATED] Salvia::Helpers::Htmx is deprecated. " \
             "Please use `Salvia::Plugins::Htmx` instead by adding " \
             "`config.plugins << :htmx` to your configuration."
        
        base.include(Salvia::Plugins::Htmx::Helpers)
        base.include(Salvia::Plugins::Htmx::ControllerMethods) if base.respond_to?(:before_action)
      end
    end
  end
end
