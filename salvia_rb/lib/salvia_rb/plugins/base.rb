# frozen_string_literal: true

module Salvia
  module Plugins
    # プラグイン管理モジュール
    #
    # Salvia のオプショナル機能をプラグインとして管理します。
    #
    # @example プラグインの有効化
    #   Salvia.configure do |config|
    #     config.plugins << :htmx
    #   end
    #
    module Base
      class << self
        # 登録済みプラグイン
        def registry
          @registry ||= {}
        end

        # プラグインを登録
        def register(name, mod)
          registry[name.to_sym] = mod
        end

        # プラグインを取得
        def get(name)
          registry[name.to_sym]
        end

        # プラグインが登録されているか確認
        def registered?(name)
          registry.key?(name.to_sym)
        end

        # 有効なプラグイン一覧
        def enabled
          @enabled ||= []
        end

        # プラグインを有効化
        def enable(name)
          plugin = get(name)
          raise ArgumentError, "Unknown plugin: #{name}" unless plugin
          
          enabled << name.to_sym unless enabled.include?(name.to_sym)
          
          # プラグインの初期化メソッドがあれば呼び出す
          plugin.setup if plugin.respond_to?(:setup)
        end

        # プラグインが有効か確認
        def enabled?(name)
          enabled.include?(name.to_sym)
        end
      end
    end
  end
end
