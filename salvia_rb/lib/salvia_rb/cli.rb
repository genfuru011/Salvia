# frozen_string_literal: true

require "thor"
require "fileutils"

module Salvia
  # Salvia フレームワークの CLI ツール
  #
  # @example
  #   salvia new myapp
  #   salvia server
  #   salvia db:migrate
  #
  class CLI < Thor
    include Thor::Actions

    # テンプレートディレクトリを指定
    def self.source_root
      File.join(__dir__, "templates")
    end

    desc "new APP_NAME", "新しい Salvia アプリケーションを作成"
    def new(app_name)
      @app_name = app_name
      @app_class_name = app_name.split(/[-_]/).map(&:capitalize).join

      say "🌿 Salvia アプリを作成中: #{@app_name}...", :green

      # ディレクトリ構造を作成
      create_directory_structure
      create_config_files
      create_app_files
      create_public_assets

      say ""
      say "💎 #{@app_name} を作成しました！", :blue
      say ""
      say "次のステップ:", :yellow
      say "  cd #{@app_name}"
      say "  bundle install"
      say "  salvia db:create"
      say "  salvia db:migrate"
      say "  salvia server"
      say ""
    end

    desc "server", "開発サーバーを起動（エイリアス: s）"
    map "s" => "server"
    method_option :port, aliases: "-p", type: :numeric, default: 9292, desc: "ポート番号"
    method_option :host, aliases: "-b", type: :string, default: "localhost", desc: "バインドするホスト"
    def server
      require_app_environment

      say "🚀 Salvia サーバーを起動: http://#{options[:host]}:#{options[:port]}", :green
      exec "bundle exec rackup -p #{options[:port]} -o #{options[:host]}"
    end

    desc "console", "対話式コンソールを起動（エイリアス: c）"
    map "c" => "console"
    def console
      require_app_environment

      require "irb"
      ARGV.clear
      IRB.start
    end

    # データベースコマンド
    desc "db:create", "データベースを作成"
    def db_create
      require_app_environment
      Salvia::Database.create!
    end

    desc "db:drop", "データベースを削除"
    def db_drop
      require_app_environment
      Salvia::Database.drop!
    end

    desc "db:migrate", "保留中のマイグレーションを実行"
    def db_migrate
      require_app_environment
      Salvia::Database.migrate!
      say "マイグレーション完了！", :green
    end

    desc "db:rollback", "直前のマイグレーションをロールバック"
    method_option :step, aliases: "-s", type: :numeric, default: 1, desc: "ロールバックするステップ数"
    def db_rollback
      require_app_environment
      Salvia::Database.rollback!(options[:step])
      say "ロールバック完了！", :green
    end

    desc "db:setup", "データベースの作成とマイグレーションを実行"
    def db_setup
      invoke :db_create
      invoke :db_migrate
    end

    # CSS コマンド
    desc "css:build", "Tailwind CSS をビルド"
    def css_build
      say "🎨 Tailwind CSS をビルド中...", :green
      system "bundle exec tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./public/assets/stylesheets/tailwind.css --minify"
      say "CSS ビルド完了！", :green
    end

    desc "css:watch", "Tailwind CSS の変更を監視してリビルド"
    def css_watch
      say "👀 CSS の変更を監視中...", :green
      exec "bundle exec tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./public/assets/stylesheets/tailwind.css --watch"
    end

    desc "routes", "登録されたルート一覧を表示"
    def routes
      require_app_environment

      say "ルート一覧:", :green
      Salvia::Router.instance.routes.each do |route|
        method = route.method.to_s.upcase.ljust(7)
        path = route.pattern.to_s.ljust(30)
        target = "#{route.controller}##{route.action}"
        say "  #{method} #{path} => #{target}"
      end
    end

    desc "version", "Salvia のバージョンを表示"
    def version
      require "salvia_rb/version"
      say "Salvia #{Salvia::VERSION}"
    end

    private

    def require_app_environment
      env_file = File.join(Dir.pwd, "config", "environment.rb")
      unless File.exist?(env_file)
        say "エラー: config/environment.rb が見つかりません。Salvia アプリのディレクトリで実行してください。", :red
        exit 1
      end
      require env_file
    end

    def create_directory_structure
      # アプリディレクトリ
      empty_directory "#{@app_name}/app/controllers"
      empty_directory "#{@app_name}/app/models"
      empty_directory "#{@app_name}/app/views/layouts"
      empty_directory "#{@app_name}/app/views/home"
      empty_directory "#{@app_name}/app/views/components"
      empty_directory "#{@app_name}/app/assets/stylesheets"

      # 設定
      empty_directory "#{@app_name}/config"

      # データベース
      empty_directory "#{@app_name}/db/migrate"

      # 公開アセット
      empty_directory "#{@app_name}/public/assets/javascripts"
      empty_directory "#{@app_name}/public/assets/stylesheets"
    end

    def create_config_files
      # Gemfile
      create_file "#{@app_name}/Gemfile", gemfile_content

      # config.ru
      create_file "#{@app_name}/config.ru", config_ru_content

      # config/environment.rb
      create_file "#{@app_name}/config/environment.rb", environment_rb_content

      # config/routes.rb
      create_file "#{@app_name}/config/routes.rb", routes_rb_content

      # config/database.yml
      create_file "#{@app_name}/config/database.yml", database_yml_content

      # Rakefile
      create_file "#{@app_name}/Rakefile", rakefile_content

      # tailwind.config.js
      create_file "#{@app_name}/tailwind.config.js", tailwind_config_content

      # .gitignore
      create_file "#{@app_name}/.gitignore", gitignore_content
    end

    def create_app_files
      # ApplicationController
      create_file "#{@app_name}/app/controllers/application_controller.rb", application_controller_content

      # HomeController
      create_file "#{@app_name}/app/controllers/home_controller.rb", home_controller_content

      # ApplicationRecord
      create_file "#{@app_name}/app/models/application_record.rb", application_record_content

      # レイアウト
      create_file "#{@app_name}/app/views/layouts/application.html.erb", layout_content

      # ホームビュー
      create_file "#{@app_name}/app/views/home/index.html.erb", home_index_content

      # Tailwind ソース CSS
      create_file "#{@app_name}/app/assets/stylesheets/application.tailwind.css", tailwind_css_content
    end

    def create_public_assets
      # HTMX - プレースホルダーを作成（ユーザーが実際のファイルをダウンロード）
      create_file "#{@app_name}/public/assets/javascripts/htmx.min.js", htmx_placeholder_content

      # app.js
      create_file "#{@app_name}/public/assets/javascripts/app.js", app_js_content

      # Tailwind CSS プレースホルダー
      create_file "#{@app_name}/public/assets/stylesheets/tailwind.css", "/* 'salvia css:build' を実行してこのファイルを生成してください */\n"

      # エラーページ
      create_file "#{@app_name}/public/404.html", error_404_content
      create_file "#{@app_name}/public/500.html", error_500_content

      say ""
      say "⚠️  HTMX を手動でダウンロードしてください:", :yellow
      say "   curl -o #{@app_name}/public/assets/javascripts/htmx.min.js https://unpkg.com/htmx.org@1.9.10/dist/htmx.min.js"
    end

    # ファイルコンテンツメソッド
    def gemfile_content
      <<~RUBY
        source "https://rubygems.org"

        gem "salvia_rb"
        gem "puma"
        gem "sqlite3"

        group :development do
          gem "debug"
        end
      RUBY
    end

    def config_ru_content
      <<~RUBY
        require_relative "config/environment"

        use Rack::Static,
          urls: ["/assets"],
          root: "public",
          header_rules: [
            [:all, { "Cache-Control" => "public, max-age=31536000" }]
          ]

        use Rack::Session::Cookie,
          key: "_#{@app_name}_session",
          secret: ENV.fetch("SESSION_SECRET") { SecureRandom.hex(64) }

        run Salvia::Application.new
      RUBY
    end

    def environment_rb_content
      <<~RUBY
        require "bundler/setup"
        require "salvia_rb"

        # アプリケーションルートを設定
        Salvia.root = File.expand_path("..", __dir__)

        # データベース設定を読み込み
        Salvia::Database.setup!

        # Zeitwerk オートローダー設定
        loader = Zeitwerk::Loader.new
        loader.push_dir(File.join(Salvia.root, "app", "controllers"))
        loader.push_dir(File.join(Salvia.root, "app", "models"))
        loader.enable_reloading if Salvia.development?
        loader.setup
        Salvia.app_loader = loader

        # ルーティングを読み込み
        require_relative "routes"
      RUBY
    end

    def routes_rb_content
      <<~RUBY
        Salvia::Router.draw do
          root to: "home#index"

          # ルートを追加
          # get "/about", to: "pages#about"
          # resources :posts
        end
      RUBY
    end

    def database_yml_content
      <<~YAML
        default: &default
          adapter: sqlite3
          pool: 5
          timeout: 5000

        development:
          <<: *default
          database: db/development.sqlite3

        test:
          <<: *default
          database: db/test.sqlite3

        production:
          adapter: postgresql
          url: <%= ENV["DATABASE_URL"] %>
      YAML
    end

    def rakefile_content
      <<~RUBY
        require_relative "config/environment"
        require "active_record"

        namespace :db do
          desc "データベースを作成"
          task :create do
            Salvia::Database.create!
          end

          desc "データベースを削除"
          task :drop do
            Salvia::Database.drop!
          end

          desc "マイグレーションを実行"
          task :migrate do
            Salvia::Database.migrate!
          end

          desc "直前のマイグレーションをロールバック"
          task :rollback do
            Salvia::Database.rollback!
          end

          desc "データベースの作成とマイグレーション"
          task :setup => [:create, :migrate]
        end
      RUBY
    end

    def tailwind_config_content
      <<~JS
        /** @type {import('tailwindcss').Config} */
        module.exports = {
          content: [
            "./app/views/**/*.erb",
            "./public/assets/javascripts/**/*.js"
          ],
          theme: {
            extend: {
              colors: {
                'salvia': {
                  50: '#f0f0ff',
                  100: '#e4e4ff',
                  200: '#cdcdff',
                  300: '#a8a8ff',
                  400: '#7c7cff',
                  500: '#6A5ACD',  // Blue Salvia
                  600: '#5a4ab8',
                  700: '#4B0082',  // Indigo
                  800: '#3d006b',
                  900: '#2d0050',
                }
              }
            },
          },
          plugins: [],
        }
      JS
    end

    def gitignore_content
      <<~TEXT
        # データベース
        db/*.sqlite3

        # Bundler
        /.bundle/
        /vendor/bundle/

        # 環境変数
        .env
        .env.local

        # ログ
        /log/*.log

        # 一時ファイル
        /tmp/

        # OS ファイル
        .DS_Store

        # IDE
        .idea/
        .vscode/
      TEXT
    end

    def application_controller_content
      <<~RUBY
        class ApplicationController < Salvia::Controller
          # 共通のコントローラーロジックをここに追加
        end
      RUBY
    end

    def home_controller_content
      <<~RUBY
        class HomeController < ApplicationController
          def index
            @title = "Salvia へようこそ"
          end
        end
      RUBY
    end

    def application_record_content
      <<~RUBY
        class ApplicationRecord < ActiveRecord::Base
          primary_abstract_class
        end
      RUBY
    end

    def layout_content
      <<~ERB
        <!DOCTYPE html>
        <html lang="ja">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title><%= @title || "#{@app_class_name}" %></title>

          <link rel="stylesheet" href="/assets/stylesheets/tailwind.css">

          <script src="/assets/javascripts/htmx.min.js" defer></script>
          <script type="module" src="/assets/javascripts/app.js"></script>
        </head>
        <body class="min-h-screen bg-slate-50 text-slate-900">
          <%= yield %>
        </body>
        </html>
      ERB
    end

    def home_index_content
      <<~ERB
        <div class="max-w-2xl mx-auto mt-16 px-4">
          <div class="text-center">
            <h1 class="text-4xl font-bold text-salvia-700 mb-4">
              🌿 Salvia へようこそ
            </h1>
            <p class="text-lg text-slate-600 mb-8">
              小さくて理解しやすい Ruby MVC フレームワーク
            </p>

            <div class="bg-white rounded-lg shadow-md p-6 text-left">
              <h2 class="text-xl font-semibold mb-4">はじめに</h2>

              <div class="space-y-3 text-sm">
                <div class="flex items-start gap-3">
                  <span class="bg-salvia-100 text-salvia-700 rounded-full w-6 h-6 flex items-center justify-center flex-shrink-0">1</span>
                  <div>
                    <code class="bg-slate-100 px-2 py-1 rounded">config/routes.rb</code>
                    <p class="text-slate-600 mt-1">ルーティングを定義</p>
                  </div>
                </div>

                <div class="flex items-start gap-3">
                  <span class="bg-salvia-100 text-salvia-700 rounded-full w-6 h-6 flex items-center justify-center flex-shrink-0">2</span>
                  <div>
                    <code class="bg-slate-100 px-2 py-1 rounded">app/controllers/</code>
                    <p class="text-slate-600 mt-1">コントローラーを追加</p>
                  </div>
                </div>

                <div class="flex items-start gap-3">
                  <span class="bg-salvia-100 text-salvia-700 rounded-full w-6 h-6 flex items-center justify-center flex-shrink-0">3</span>
                  <div>
                    <code class="bg-slate-100 px-2 py-1 rounded">app/views/</code>
                    <p class="text-slate-600 mt-1">ERB + HTMX でビューを作成</p>
                  </div>
                </div>
              </div>
            </div>

            <p class="mt-8 text-sm text-slate-500">
              <code class="bg-slate-100 px-2 py-0.5 rounded">app/views/home/index.html.erb</code> を編集してこのページを変更
            </p>
          </div>
        </div>
      ERB
    end

    def tailwind_css_content
      <<~CSS
        @tailwind base;
        @tailwind components;
        @tailwind utilities;
      CSS
    end

    def htmx_placeholder_content
      <<~JS
        // HTMX プレースホルダー - 実際のファイルをダウンロードしてください:
        // curl -o public/assets/javascripts/htmx.min.js https://unpkg.com/htmx.org@1.9.10/dist/htmx.min.js
        console.warn("HTMX が読み込まれていません。htmx.min.js をダウンロードしてください。");
      JS
    end

    def app_js_content
      <<~JS
        // Salvia アプリのカスタム JavaScript

        // HTMX の設定（オプション）
        document.addEventListener('htmx:configRequest', (event) => {
          // 必要に応じて CSRF トークンを HTMX リクエストに追加
          // const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
          // if (csrfToken) {
          //   event.detail.headers['X-CSRF-Token'] = csrfToken;
          // }
        });

        // 開発環境で HTMX イベントをログ出力
        if (window.location.hostname === 'localhost') {
          document.addEventListener('htmx:afterSwap', (event) => {
            console.log('HTMX swap:', event.detail.target);
          });
        }
      JS
    end

    def error_404_content
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>ページが見つかりません (404)</title>
          <meta charset="utf-8">
          <style>
            body { font-family: system-ui, sans-serif; color: #333; text-align: center; padding: 100px 20px; }
            h1 { font-size: 3em; margin-bottom: 10px; color: #6A5ACD; }
            p { font-size: 1.2em; color: #666; }
            a { color: #6A5ACD; text-decoration: none; }
            a:hover { text-decoration: underline; }
          </style>
        </head>
        <body>
          <h1>404</h1>
          <p>お探しのページは見つかりませんでした。</p>
          <p><a href="/">トップページへ戻る</a></p>
        </body>
        </html>
      HTML
    end

    def error_500_content
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>サーバーエラー (500)</title>
          <meta charset="utf-8">
          <style>
            body { font-family: system-ui, sans-serif; color: #333; text-align: center; padding: 100px 20px; }
            h1 { font-size: 3em; margin-bottom: 10px; color: #dc2626; }
            p { font-size: 1.2em; color: #666; }
          </style>
        </head>
        <body>
          <h1>500</h1>
          <p>サーバー内部でエラーが発生しました。</p>
          <p>しばらくしてからもう一度お試しください。</p>
        </body>
        </html>
      HTML
    end
  end
end
