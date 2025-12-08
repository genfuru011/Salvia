# frozen_string_literal: true

require "mustermann"
require "active_support/core_ext/string/inflections"

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
        method.to_s.upcase == request_method && pattern.match(path)
      end

      def params_from(path)
        pattern.params(path) || {}
      end
    end

    class << self
      def instance
        @instance ||= new
      end

      def helpers
        @helpers ||= Module.new
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
      @scope = { path: "", as: [] }
    end

    # ルートルートを定義
    # @example root to: "home#index"
    def root(to:)
      get "/", to: to, as: "root"
    end

    # HTTP メソッドルートを定義
    HTTP_METHODS.each do |method|
      define_method(method) do |path, to:, as: nil|
        controller, action = to.split("#")
        add_route(method, path, controller, action, as: as)
      end
    end

    # RESTful リソースヘルパー
    # @example resources :todos, only: [:index, :create, :destroy]
    def resources(name, only: nil, except: nil, &block)
      actions = %i[index show new create edit update destroy]
      actions = only if only
      actions -= except if except

      prefix = @scope[:as].join("_")
      prefix = "#{prefix}_" unless prefix.empty?
      singular = name.to_s.singularize

      resource_routes = {
        index:   [:get,    "/#{name}",               "#{prefix}#{name}"],
        show:    [:get,    "/#{name}/:id",           "#{prefix}#{singular}"],
        new:     [:get,    "/#{name}/new",           "#{prefix}new_#{singular}"],
        create:  [:post,   "/#{name}",               nil],
        edit:    [:get,    "/#{name}/:id/edit",      "#{prefix}edit_#{singular}"],
        update:  [:patch,  "/#{name}/:id",           nil],
        destroy: [:delete, "/#{name}/:id",           nil]
      }

      controller = name.to_s

      actions.each do |action|
        method, path, as = resource_routes[action]
        add_route(method, path, controller, action.to_s, as: as) if method
      end

      if block_given?
        parent_param = "#{singular}_id"
        nested_path = "/#{name}/:#{parent_param}"
        with_scope(path: nested_path, as: singular) do
          block.call
        end
      end
    end

    # リクエストにマッチするルートを検索
    # @param request [Rack::Request]
    # @return [Array<Class, String, Hash>] [コントローラークラス, アクション, パラメータ] または nil
    def recognize(request)
      request_method = request.request_method
      request_method = "GET" if request_method == "HEAD"
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

    def with_scope(options)
      old_scope = @scope.dup
      if options[:path]
        @scope[:path] = File.join(@scope[:path], options[:path])
      end
      if options[:as]
        @scope[:as] << options[:as]
      end
      yield
    ensure
      @scope = old_scope
    end

    def add_route(method, path, controller, action, as: nil)
      full_path = File.join(@scope[:path], path)
      pattern = Mustermann.new(full_path, type: :rails)

      if as
        helper_name = "#{as}_path"
        Salvia::Router.helpers.define_method(helper_name) do |*args|
          params = {}
          params = args.pop if args.last.is_a?(Hash)
          pattern.names.each_with_index do |name, i|
            params[name] = args[i] if i < args.length
          end
          pattern.expand(params)
        end
      end

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
