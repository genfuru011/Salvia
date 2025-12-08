# frozen_string_literal: true

require "json"

module Salvia
  # Import Map を管理するクラス
  #
  # @example
  #   Salvia.importmap.draw do
  #     pin "preact", to: "https://esm.sh/preact@10"
  #     pin "app", to: "/assets/javascripts/app.js"
  #   end
  class ImportMap
    def initialize
      @packages = {}
    end

    # Import Map を定義する DSL
    def draw(&block)
      instance_eval(&block)
    end

    # パッケージをピン留めする
    #
    # @param name [String] パッケージ名
    # @param to [String] URL またはパス
    def pin(name, to:)
      @packages[name] = to
    end

    # JSON 文字列に変換
    def to_json(*_args)
      { imports: @packages }.to_json
    end
  end
end
