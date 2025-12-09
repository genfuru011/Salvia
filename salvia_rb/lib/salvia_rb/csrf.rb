# frozen_string_literal: true

require "securerandom"

module Salvia
  # CSRF (Cross-Site Request Forgery) 保護モジュール
  #
  # SSR Islands と互換性のある Global Token 方式を採用
  # Rack::Protection より軽量でシンプルな実装
  #
  module CSRF
    TOKEN_LENGTH = 32
    SESSION_KEY = :csrf_token
    HEADER_NAME = "HTTP_X_CSRF_TOKEN"
    PARAM_NAME = "authenticity_token"

    class << self
      # セッションから CSRF トークンを取得（なければ生成）
      #
      # @param session [Hash] Rack セッション
      # @return [String] CSRF トークン
      def token(session)
        session[SESSION_KEY] ||= SecureRandom.urlsafe_base64(TOKEN_LENGTH)
      end

      # CSRF トークンを検証
      #
      # @param session [Hash] Rack セッション
      # @param token [String] 検証するトークン
      # @return [Boolean] 有効なら true
      def valid?(session, token)
        return false if token.nil? || token.empty?
        return false if session[SESSION_KEY].nil?

        Rack::Utils.secure_compare(session[SESSION_KEY], token)
      end

      # 安全な HTTP メソッドか判定
      # GET, HEAD, OPTIONS, TRACE は CSRF 検証不要
      #
      # @param method [String] HTTP メソッド
      # @return [Boolean] 安全なら true
      def safe_method?(method)
        %w[GET HEAD OPTIONS TRACE].include?(method.to_s.upcase)
      end

      # リクエストから CSRF トークンを抽出
      #
      # @param request [Rack::Request] リクエスト
      # @return [String, nil] トークン
      def extract_token(request)
        # 1. ヘッダーから (JavaScript fetch 用)
        request.env[HEADER_NAME] ||
          # 2. POST パラメータから (HTML フォーム用)
          request.params[PARAM_NAME]
      end
    end

    # CSRF 保護ミドルウェア
    #
    # @example config.ru
    #   use Salvia::CSRF::Protection
    #
    class Protection
      def initialize(app, options = {})
        @app = app
        @options = {
          raise_on_failure: false,
          skip: [],           # スキップするパスの配列
          skip_if: nil        # スキップ条件の Proc
        }.merge(options)
      end

      def call(env)
        request = Rack::Request.new(env)

        # 安全なメソッドはスキップ
        return @app.call(env) if CSRF.safe_method?(request.request_method)

        # スキップ設定をチェック
        return @app.call(env) if skip_request?(request)

        # セッションを取得
        session = env["rack.session"]
        unless session
          raise "CSRF protection requires session middleware"
        end

        # トークンを検証
        token = CSRF.extract_token(request)
        unless CSRF.valid?(session, token)
          return handle_failure(env, request)
        end

        @app.call(env)
      end

      private

      def skip_request?(request)
        # パスによるスキップ
        if @options[:skip].any? { |path| request.path.start_with?(path) }
          return true
        end

        # カスタム条件によるスキップ
        if @options[:skip_if]&.call(request)
          return true
        end

        false
      end

      def handle_failure(env, request)
        if @options[:raise_on_failure]
          raise InvalidTokenError, "CSRF token verification failed"
        end

        # 403 Forbidden を返す
        [
          403,
          { "content-type" => "text/plain" },
          ["Forbidden - Invalid CSRF token"]
        ]
      end
    end

    class InvalidTokenError < StandardError; end
  end
end
