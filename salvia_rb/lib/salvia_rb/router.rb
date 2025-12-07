# frozen_string_literal: true

require "mustermann"

module Salvia
  # Rails ライクな DSL ルーター（Mustermann ベース）
  #
  # @example
  #   Salvia::Router.draw do
  #     root to: "home#index"
  #     get "/about", to: "pages#about"
  #     resources :todos, only: [:index, :create, :destroy]
  #   end
  #
  class Router
    HTTP_METHODS = %i[get post put patch delete].freeze

    Route = Struct.new(:method, :pattern, :controller, :action, keyword_init: true) do
      def match?(request_method, path)
        method.to_s.upcase == request_method && pattern.match?(path)
      end

      def params_from(path)
        pattern.params(path) || {}
      end
    end

    class << self
      def instance
        @instance ||= new
      end

      def draw(&block)
        instance.instance_eval(&block)
        instance
      end

      def recognize(request)
        instance.recognize(request)
      end

      def reset!
        @instance = nil
      end
    end

    def initialize
      @routes = []
    end

    # ルートルートを定義
    # @example root to: "home#index"
    def root(to:)
      get "/", to: to
    end

    # HTTP メソッドルートを定義
    HTTP_METHODS.each do |method|
      define_method(method) do |path, to:|
        controller, action = to.split("#")
        add_route(method, path, controller, action)
      end
    end

    # RESTful リソースヘルパー
    # @example resources :todos, only: [:index, :create, :destroy]
    def resources(name, only: nil, except: nil)
      actions = %i[index show new create edit update destroy]
      actions = only if only
      actions -= except if except

      resource_routes = {
        index:   [:get,    "/#{name}"],
        show:    [:get,    "/#{name}/:id"],
        new:     [:get,    "/#{name}/new"],
        create:  [:post,   "/#{name}"],
        edit:    [:get,    "/#{name}/:id/edit"],
        update:  [:patch,  "/#{name}/:id"],
        destroy: [:delete, "/#{name}/:id"]
      }

      controller = name.to_s

      actions.each do |action|
        method, path = resource_routes[action]
        add_route(method, path, controller, action.to_s) if method
      end
    end

    # リクエストにマッチするルートを検索
    # @param request [Rack::Request]
    # @return [Array<Class, String, Hash>] [コントローラークラス, アクション, パラメータ] または nil
    def recognize(request)
      request_method = request.request_method
      path = request.path_info

      @routes.each do |route|
        next unless route.match?(request_method, path)

        controller_class = resolve_controller(route.controller)
        return nil unless controller_class

        params = route.params_from(path)
        return [controller_class, route.action, params]
      end

      nil
    end

    # 登録されたルート一覧を取得（デバッグ用）
    def routes
      @routes.dup
    end

    private

    def add_route(method, path, controller, action)
      pattern = Mustermann.new(path, type: :rails)
      @routes << Route.new(
        method: method,
        pattern: pattern,
        controller: controller,
        action: action
      )
    end

    def resolve_controller(name)
      # "home" を "HomeController" に変換
      class_name = "#{name.split('_').map(&:capitalize).join}Controller"
      Object.const_get(class_name)
    rescue NameError
      nil
    end
  end
end
