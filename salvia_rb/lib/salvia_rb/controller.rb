# frozen_string_literal: true

require "tilt"
require "tilt/erubi"
require "rack"

module Salvia
  # Smart Rendering 対応の基底コントローラークラス
  #
  # Smart Rendering は HTMX リクエストを自動検出し、
  # 部分更新時にはレイアウトを除外してレンダリングします。
  #
  # @example
  #   class HomeController < Salvia::Controller
  #     def index
  #       @todos = Todo.all
  #       render "home/index"
  #     end
  #
  #     def create
  #       Todo.create!(title: params["title"])
  #       @todos = Todo.all
  #       render "home/_list", locals: { todos: @todos }
  #     end
  #   end
  #
  class Controller
    attr_reader :request, :response, :params

    def initialize(request, response, route_params = {})
      @request = request
      @response = response
      @params = request.params.merge(route_params)
      @rendered = false
    end

    # コントローラーアクションを実行
    def process(action_name)
      send(action_name)
      render(default_template(action_name)) unless @rendered
    end

    # Smart Rendering 対応のテンプレートレンダリング
    #
    # @param template [String] テンプレートパス（例: "home/index" or "home/_list"）
    # @param locals [Hash] テンプレートに渡すローカル変数
    # @param layout [String, nil, false] レイアウト（nil = 自動, false = なし）
    # @param status [Integer] HTTP ステータスコード
    def render(template, locals: {}, layout: nil, status: 200)
      @rendered = true
      response.status = status
      response["Content-Type"] = "text/html; charset=utf-8"

      # インスタンス変数をテンプレートに渡す
      template_locals = instance_variables_hash.merge(locals)

      # メインテンプレートをレンダリング
      content = render_template(template, template_locals)

      # Smart Rendering: HTMX リクエストはデフォルトでレイアウトなし
      use_layout = determine_layout(layout, template)

      if use_layout
        body = render_template(use_layout, template_locals) { content }
      else
        body = content
      end

      response.write(body)
    end

    # パーシャルテンプレートをレンダリング（レイアウトなし）
    def render_partial(template, locals: {}, status: 200)
      render(template, locals: locals, layout: false, status: status)
    end

    # 別の URL にリダイレクト
    #
    # @param url [String] リダイレクト先 URL
    # @param status [Integer] HTTP ステータスコード（デフォルト: 302）
    def redirect_to(url, status: 302)
      @rendered = true
      response.status = status
      response["Location"] = url

      # HTMX リクエストには HX-Redirect ヘッダーを使用
      if htmx_request?
        response["HX-Redirect"] = url
      end
    end

    # HTMX からのリクエストかどうかを判定
    #
    # @return [Boolean]
    def htmx_request?
      request.env["HTTP_HX_REQUEST"] == "true"
    end

    # セッションにアクセス
    def session
      request.session
    end

    # Flash メッセージにアクセス（セッションミドルウェアが必要）
    def flash
      session[:flash] ||= {}
    end

    # HTMX イベントをトリガー
    #
    # @param event [String] イベント名
    # @param detail [Hash] イベント詳細データ
    def htmx_trigger(event, detail = {})
      response["HX-Trigger"] = { event => detail }.to_json
    end

    protected

    # サブクラスでオーバーライドしてデフォルトレイアウトを設定
    def default_layout
      "layouts/application"
    end

    private

    def determine_layout(layout_option, template)
      # 明示的に false = レイアウトなし
      return false if layout_option == false

      # パーシャル（_ で始まる）はデフォルトでレイアウトなし
      template_name = File.basename(template)
      return false if template_name.start_with?("_")

      # HTMX リクエストはデフォルトでレイアウトなし（Smart Rendering）
      return false if htmx_request?

      # 指定されたレイアウトまたはデフォルトを使用
      layout_option || default_layout
    end

    def render_template(template_path, locals = {}, &block)
      full_path = resolve_template_path(template_path)

      unless File.exist?(full_path)
        raise Error, "テンプレートが見つかりません: #{full_path}"
      end

      template = Tilt.new(full_path)
      template.render(self, locals, &block)
    end

    def resolve_template_path(template)
      # 拡張子が含まれている場合
      return File.join(views_path, template) if template.end_with?(".erb")

      # 一般的な拡張子を試す
      base = File.join(views_path, template)
      ["#{base}.html.erb", "#{base}.erb"].find { |p| File.exist?(p) } || "#{base}.html.erb"
    end

    def views_path
      File.join(Salvia.root, "app", "views")
    end

    def default_template(action_name)
      controller_name = self.class.name.sub(/Controller$/, "").downcase
      "#{controller_name}/#{action_name}"
    end

    def instance_variables_hash
      instance_variables
        .reject { |v| v.to_s.start_with?("@_") || %i[@request @response @params @rendered].include?(v) }
        .each_with_object({}) { |v, h| h[v.to_s.delete("@").to_sym] = instance_variable_get(v) }
    end
  end
end
