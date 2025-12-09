# frozen_string_literal: true

require "thor"
require "fileutils"
require "tty-prompt"

module Salvia
  # Salvia フレームワークの CLI ツール
  #
  # @example
  #   salvia new myapp
  #   salvia server
  #   salvia generate controller posts
  #
  class CLI < Thor
    include Thor::Actions

    # テンプレートディレクトリ
    def self.source_root
      File.join(__dir__, "templates")
    end

    desc "new APP_NAME", "Create a new Salvia application"
    method_option :template, aliases: "-t", type: :string, desc: "Template: full, api, minimal"
    method_option :islands, type: :boolean, desc: "Include SSR Islands"
    method_option :skip_prompts, type: :boolean, default: false, desc: "Skip interactive prompts"
    def new(app_name)
      @app_name = app_name
      @app_class_name = app_name.split(/[-_]/).map(&:capitalize).join
      @prompt = TTY::Prompt.new

      say ""
      say "🌿 Creating Salvia app: #{@app_name}", :green
      say ""

      # 対話式プロンプト（スキップでなければ）
      if options[:skip_prompts]
        @template = options[:template] || "full"
        @include_islands = options[:islands].nil? ? true : options[:islands]
      else
        @template = options[:template] || select_template
        @include_islands = options[:islands].nil? ? prompt_islands : options[:islands]
      end

      say ""
      say "📦 Template: #{@template}", :cyan
      say "🏝️  Islands: #{@include_islands ? 'Yes' : 'No'}", :cyan
      say ""

      # ディレクトリ構造を作成
      create_directory_structure
      create_config_files
      create_app_files
      create_public_assets

      say ""
      say "✨ Created #{@app_name}!", :green
      say ""
      say "Next steps:", :yellow
      say "  cd #{@app_name}"
      say "  bundle install"
      say "  salvia db:create"
      say "  salvia db:migrate"
      say "  salvia css:build"
      if @include_islands
        say "  salvia ssr:build"
      end
      say "  salvia server"
      say ""
    end

    desc "generate GENERATOR NAME", "Generate controller, model, or migration (alias: g)"
    map "g" => "generate"
    def generate(generator, name, *args)
      case generator.downcase
      when "controller"
        generate_controller(name, args)
      when "model"
        generate_model(name, args)
      when "migration"
        generate_migration(name, args)
      else
        say "Unknown generator: #{generator}", :red
        say "Available: controller, model, migration", :yellow
      end
    end

    desc "server", "Start development server (alias: s)"
    map "s" => "server"
    method_option :port, aliases: "-p", type: :numeric, default: 9292, desc: "Port number"
    method_option :host, aliases: "-b", type: :string, default: "localhost", desc: "Host to bind"
    def server
      require_app_environment

      say "🚀 Starting Salvia server: http://#{options[:host]}:#{options[:port]}", :green
      exec "bundle exec rackup -p #{options[:port]} -o #{options[:host]}"
    end

    desc "console", "Start interactive console (alias: c)"
    map "c" => "console"
    def console
      require_app_environment

      require "irb"
      ARGV.clear
      IRB.start
    end

    # Database commands
    desc "db:create", "Create database"
    map "db:create" => :db_create
    def db_create
      require_app_environment
      Salvia::Database.create!
    end

    desc "db:drop", "Drop database"
    map "db:drop" => :db_drop
    def db_drop
      require_app_environment
      Salvia::Database.drop!
    end

    desc "db:migrate", "Run pending migrations"
    map "db:migrate" => :db_migrate
    def db_migrate
      require_app_environment
      Salvia::Database.migrate!
      say "Migration completed!", :green
    end

    desc "db:rollback", "Rollback last migration"
    map "db:rollback" => :db_rollback
    method_option :step, aliases: "-s", type: :numeric, default: 1, desc: "Steps to rollback"
    def db_rollback
      require_app_environment
      Salvia::Database.rollback!(options[:step])
      say "Rollback completed!", :green
    end

    desc "db:setup", "Create database and run migrations"
    map "db:setup" => :db_setup
    def db_setup
      invoke :db_create
      invoke :db_migrate
    end

    # CSS commands
    desc "css:build", "Build Tailwind CSS"
    map "css:build" => :css_build
    def css_build
      say "🎨 Building Tailwind CSS...", :green
      system "bundle exec tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./public/assets/stylesheets/tailwind.css --minify"
      say "CSS build completed!", :green
    end

    desc "css:watch", "Watch and rebuild Tailwind CSS"
    map "css:watch" => :css_watch
    def css_watch
      say "👀 Watching CSS changes...", :green
      exec "bundle exec tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./public/assets/stylesheets/tailwind.css --watch"
    end

    desc "assets:precompile", "Precompile assets with hash"
    map "assets:precompile" => :assets_precompile
    def assets_precompile
      require_app_environment
      Salvia::Assets.precompile!
    end

    desc "routes", "Display registered routes"
    def routes
      require_app_environment

      say "Routes:", :green
      Salvia::Router.instance.routes.each do |route|
        method = route.method.to_s.upcase.ljust(7)
        path = route.pattern.to_s.ljust(30)
        target = "#{route.controller}##{route.action}"
        say "  #{method} #{path} => #{target}"
      end
    end

    desc "version", "Display Salvia version"
    def version
      require "salvia_rb/version"
      say "Salvia #{Salvia::VERSION}"
    end

    # SSR commands
    desc "ssr:build", "Build Island components for SSR"
    map "ssr:build" => :ssr_build
    method_option :verbose, aliases: "-v", type: :boolean, default: false, desc: "Verbose output"
    def ssr_build
      check_deno_installed!
      
      say "🏝️  Building Island components...", :green
      
      cmd = "deno run --allow-all bin/build_ssr.ts"
      cmd += " --verbose" if options[:verbose]
      
      success = system(cmd)
      
      if success
        say "✅ SSR build completed!", :green
      else
        say "❌ SSR build failed", :red
        exit 1
      end
    end

    desc "ssr:watch", "Watch and rebuild Island components"
    map "ssr:watch" => :ssr_watch
    method_option :verbose, aliases: "-v", type: :boolean, default: false, desc: "Verbose output"
    def ssr_watch
      check_deno_installed!
      
      say "👀 Watching Island components...", :green
      
      cmd = "deno run --allow-all bin/build_ssr.ts --watch"
      cmd += " --verbose" if options[:verbose]
      
      exec cmd
    end

    desc "dev", "Start server + SSR watch together"
    method_option :port, aliases: "-p", type: :numeric, default: 9292, desc: "Port number"
    method_option :host, aliases: "-b", type: :string, default: "localhost", desc: "Host to bind"
    def dev
      require_app_environment
      
      say "🚀 Starting Salvia dev mode...", :green
      say "   Server: http://#{options[:host]}:#{options[:port]}", :cyan
      say "   SSR Watch: enabled", :cyan
      say ""
      
      # Deno SSR watch in background
      deno_pid = nil
      if deno_installed?
        deno_pid = spawn("deno run --allow-all bin/build_ssr.ts --watch",
                         out: "/dev/null", err: [:child, :out])
        say "🏝️  SSR watch started (PID: #{deno_pid})", :blue
      else
        say "⚠️  Deno not found. Skipping SSR build.", :yellow
      end
      
      # Cleanup on exit
      at_exit do
        if deno_pid
          Process.kill("TERM", deno_pid) rescue nil
          Process.wait(deno_pid) rescue nil
        end
      end
      
      # Tailwind CSS watch in background
      tailwind_pid = spawn("bundle exec tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./public/assets/stylesheets/tailwind.css --watch",
                           out: "/dev/null", err: [:child, :out])
      say "🎨 CSS watch started (PID: #{tailwind_pid})", :blue
      
      at_exit do
        Process.kill("TERM", tailwind_pid) rescue nil
        Process.wait(tailwind_pid) rescue nil
      end
      
      say ""
      
      # Start Ruby server
      exec "bundle exec rackup -p #{options[:port]} -o #{options[:host]}"
    end

    private

    # ========================================
    # 対話式プロンプト
    # ========================================

    def select_template
      @prompt.select("What template would you like?", cycle: true) do |menu|
        menu.choice "Full app (ERB + Database + Views)", "full"
        menu.choice "API only (JSON responses, no views)", "api"
        menu.choice "Minimal (bare Rack app)", "minimal"
      end
    end

    def prompt_islands
      @prompt.yes?("Include SSR Islands? (Preact components)")
    end

    # ========================================
    # ジェネレーター
    # ========================================

    def generate_controller(name, actions)
      @controller_name = name.downcase
      @controller_class = name.split(/[-_]/).map(&:capitalize).join + "Controller"
      @actions = actions.empty? ? ["index"] : actions

      say "🎮 Generating controller: #{@controller_class}", :green

      # コントローラーファイル
      create_file "app/controllers/#{@controller_name}_controller.rb", controller_generator_content

      # ビューファイル
      @actions.each do |action|
        empty_directory "app/views/#{@controller_name}"
        create_file "app/views/#{@controller_name}/#{action}.html.erb", view_generator_content(action)
      end

      # テストファイル
      empty_directory "test/controllers"
      create_file "test/controllers/#{@controller_name}_controller_test.rb", controller_test_generator_content

      say ""
      say "Add routes to config/routes.rb:", :yellow
      @actions.each do |action|
        say "  get \"/#{@controller_name}/#{action}\", to: \"#{@controller_name}##{action}\""
      end
      say ""
    end

    def generate_model(name, fields)
      @model_name = name.downcase
      @model_class = name.split(/[-_]/).map(&:capitalize).join
      @table_name = @model_name + "s"
      @fields = parse_fields(fields)

      say "📦 Generating model: #{@model_class}", :green

      # モデルファイル
      create_file "app/models/#{@model_name}.rb", model_generator_content

      # マイグレーションファイル
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      empty_directory "db/migrate"
      create_file "db/migrate/#{timestamp}_create_#{@table_name}.rb", model_migration_content

      # テストファイル
      empty_directory "test/models"
      create_file "test/models/#{@model_name}_test.rb", model_test_generator_content

      say ""
      say "Run migration:", :yellow
      say "  salvia db:migrate"
      say ""
    end

    def generate_migration(name, fields)
      @migration_name = name
      @migration_class = name.split(/[-_]/).map(&:capitalize).join
      @fields = parse_fields(fields)

      say "📝 Generating migration: #{@migration_class}", :green

      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      empty_directory "db/migrate"
      create_file "db/migrate/#{timestamp}_#{name.downcase}.rb", migration_generator_content

      say ""
      say "Run migration:", :yellow
      say "  salvia db:migrate"
      say ""
    end

    def parse_fields(fields)
      fields.map do |field|
        parts = field.split(":")
        { name: parts[0], type: parts[1] || "string" }
      end
    end

    # ジェネレーターコンテンツメソッド

    def controller_generator_content
      actions_code = @actions.map do |action|
        <<~RUBY
          def #{action}
            # TODO: implement #{action}
          end
        RUBY
      end.join("\n")

      <<~RUBY
        class #{@controller_class} < ApplicationController
        #{actions_code.lines.map { |l| "  #{l}" }.join.chomp}
        end
      RUBY
    end

    def view_generator_content(action)
      <<~ERB
        <div class="max-w-4xl mx-auto mt-8 px-4">
          <h1 class="text-2xl font-bold mb-4">#{@controller_class}##{action}</h1>
          <p class="text-slate-600">Edit this view at <code class="bg-slate-100 px-2 py-1 rounded">app/views/#{@controller_name}/#{action}.html.erb</code></p>
        </div>
      ERB
    end

    def controller_test_generator_content
      tests = @actions.map do |action|
        <<~RUBY
          def test_#{action}
            get "/#{@controller_name}/#{action}"
            assert last_response.ok?
          end
        RUBY
      end.join("\n")

      <<~RUBY
        require_relative "../test_helper"

        class #{@controller_class}Test < Minitest::Test
        #{tests.lines.map { |l| "  #{l}" }.join.chomp}
        end
      RUBY
    end

    def model_generator_content
      <<~RUBY
        class #{@model_class} < ApplicationRecord
          # Add validations and associations here
        end
      RUBY
    end

    def model_migration_content
      fields_code = @fields.map do |field|
        "      t.#{field[:type]} :#{field[:name]}"
      end.join("\n")

      <<~RUBY
        class Create#{@table_name.capitalize} < ActiveRecord::Migration[7.0]
          def change
            create_table :#{@table_name} do |t|
        #{fields_code}
              t.timestamps
            end
          end
        end
      RUBY
    end

    def model_test_generator_content
      <<~RUBY
        require_relative "../test_helper"

        class #{@model_class}Test < Minitest::Test
          def test_create
            # TODO: implement test
          end
        end
      RUBY
    end

    def migration_generator_content
      if @migration_name.start_with?("add_")
        # add_X_to_Y pattern
        match = @migration_name.match(/add_(.+)_to_(.+)/)
        if match
          table = match[2]
          fields_code = @fields.map do |field|
            "    add_column :#{table}, :#{field[:name]}, :#{field[:type]}"
          end.join("\n")

          return <<~RUBY
            class #{@migration_class} < ActiveRecord::Migration[7.0]
              def change
            #{fields_code}
              end
            end
          RUBY
        end
      end

      # Generic migration
      <<~RUBY
        class #{@migration_class} < ActiveRecord::Migration[7.0]
          def change
            # TODO: implement migration
          end
        end
      RUBY
    end

    # ========================================
    # ユーティリティメソッド
    # ========================================

    def check_deno_installed!
      unless deno_installed?
        say "❌ Deno is not installed.", :red
        say ""
        say "Install:", :yellow
        say "  curl -fsSL https://deno.land/install.sh | sh"
        say ""
        say "Or visit: https://deno.land", :yellow
        exit 1
      end
    end

    def deno_installed?
      system("which deno > /dev/null 2>&1")
    end

    def require_app_environment
      env_file = File.join(Dir.pwd, "config", "environment.rb")
      unless File.exist?(env_file)
        say "Error: config/environment.rb not found. Run this command in a Salvia app directory.", :red
        exit 1
      end
      require env_file
    end

    def create_directory_structure
      # アプリディレクトリ
      empty_directory "#{@app_name}/app/controllers"
      empty_directory "#{@app_name}/app/models"
      
      unless @template == "api"
        empty_directory "#{@app_name}/app/views/layouts"
        empty_directory "#{@app_name}/app/views/home"
        empty_directory "#{@app_name}/app/components"
      end
      
      if @include_islands
        empty_directory "#{@app_name}/app/islands"
      end
      
      empty_directory "#{@app_name}/app/assets/stylesheets"

      # 設定
      empty_directory "#{@app_name}/config"
      empty_directory "#{@app_name}/config/environments"

      # データベース（minimal以外）
      unless @template == "minimal"
        empty_directory "#{@app_name}/db/migrate"
      end

      # ログ
      empty_directory "#{@app_name}/log"

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

      # config/database.yml (unless minimal)
      unless @template == "minimal"
        create_file "#{@app_name}/config/database.yml", database_yml_content
      end

      # config/environments
      create_file "#{@app_name}/config/environments/development.rb", development_config_content
      create_file "#{@app_name}/config/environments/production.rb", production_config_content

      # Rakefile
      create_file "#{@app_name}/Rakefile", rakefile_content

      # テスト
      empty_directory "#{@app_name}/test"
      create_file "#{@app_name}/test/test_helper.rb", test_helper_content
      
      unless @template == "minimal"
        create_file "#{@app_name}/test/controllers/home_controller_test.rb", home_controller_test_content
      end

      # tailwind.config.js
      create_file "#{@app_name}/tailwind.config.js", tailwind_config_content

      # .gitignore
      create_file "#{@app_name}/.gitignore", gitignore_content
    end

    def create_app_files
      # ApplicationController
      create_file "#{@app_name}/app/controllers/application_controller.rb", application_controller_content

      # HomeController（minimal以外）
      unless @template == "minimal"
        create_file "#{@app_name}/app/controllers/home_controller.rb", home_controller_content
      end

      # ApplicationRecord（minimal以外）
      unless @template == "minimal"
        create_file "#{@app_name}/app/models/application_record.rb", application_record_content
      end

      # ビュー（API/minimal以外）
      unless @template == "api" || @template == "minimal"
        create_file "#{@app_name}/app/views/layouts/application.html.erb", layout_content
        create_file "#{@app_name}/app/views/home/index.html.erb", home_index_content
      end

      # Tailwind ソース CSS
      create_file "#{@app_name}/app/assets/stylesheets/application.tailwind.css", tailwind_css_content
    end

    def create_public_assets
      # アプリケーション JS
      create_file "#{@app_name}/public/assets/javascripts/app.js", app_js_content

      # Islands JS（ハイドレーション）- Islands を含む場合のみ
      if @include_islands
        create_file "#{@app_name}/public/assets/javascripts/islands.js", islands_js_content
      end

      # Tailwind CSS プレースホルダー
      create_file "#{@app_name}/public/assets/stylesheets/tailwind.css", "/* Run 'salvia css:build' to generate */\n"

      # エラーページ
      create_file "#{@app_name}/public/404.html", error_404_content
      create_file "#{@app_name}/public/500.html", error_500_content

      # SSR ビルドスクリプト - Islands を含む場合のみ
      if @include_islands
        create_file "#{@app_name}/bin/build_ssr.ts", build_ssr_ts_content
        empty_directory "#{@app_name}/vendor/server"
      end
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
            [:all, { "cache-control" => "public, max-age=31536000" }]
          ]

        # Islands 用 (app/islands を /islands として公開)
        use Rack::Static,
          urls: ["/islands"],
          root: "app"

        use Rack::Session::Cookie,
          key: "_#{@app_name}_session",
          secret: ENV.fetch("SESSION_SECRET") { SecureRandom.hex(64) }

        use Rack::Protection, use: [:authenticity_token, :cookie_tossing, :form_token, :remote_referrer, :session_hijacking]

        # ロギング
        use Rack::CommonLogger, Salvia.logger

        run Salvia::Application.new
      RUBY
    end

    def environment_rb_content
      <<~RUBY
        require "bundler/setup"
        require "salvia_rb"

        # Set application root
        Salvia.root = File.expand_path("..", __dir__)

        # Application configuration
        Salvia.configure do |config|
          # config.ssr_bundle_path = "vendor/server/ssr_bundle.js"
        end

        # Setup database
        Salvia::Database.setup!

        # Load environment config
        Salvia.load_config

        # Zeitwerk autoloader
        loader = Zeitwerk::Loader.new
        loader.push_dir(File.join(Salvia.root, "app", "controllers"))
        loader.push_dir(File.join(Salvia.root, "app", "models"))
        loader.push_dir(File.join(Salvia.root, "app", "components"))
        loader.enable_reloading if Salvia.development?
        loader.setup
        Salvia.app_loader = loader

        # Load routes
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

    def test_helper_content
      <<~RUBY
        ENV["RACK_ENV"] = "test"
        require_relative "../config/environment"
        require "minitest/autorun"
        require "salvia_rb/test"

        class Minitest::Test
          include Salvia::Test::ControllerHelper
        end
      RUBY
    end

    def home_controller_test_content
      <<~RUBY
        require_relative "../test_helper"

        class HomeControllerTest < Minitest::Test
          def test_index
            get "/"
            assert last_response.ok?
            assert_includes last_response.body, "Salvia"
          end
        end
      RUBY
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
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title><%= @title || "#{@app_class_name}" %></title>

          <%= csrf_meta_tags %>

          <link rel="stylesheet" href="/assets/stylesheets/tailwind.css">
          <script type="module" src="/assets/javascripts/app.js"></script>
          <script type="module" src="/assets/javascripts/islands.js"></script>

          <% if Salvia.development? && Salvia.config.island_inspector? %>
            <%= island_inspector_tags %>
          <% end %>
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

    def app_js_content
      <<~JS
        // Salvia application JavaScript
        
        // Add custom initialization code here
        console.log('🌿 Salvia app loaded');
      JS
    end

    def error_404_content
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>Page Not Found (404)</title>
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
          <p>The page you're looking for could not be found.</p>
          <p><a href="/">Back to Home</a></p>
        </body>
        </html>
      HTML
    end

    def error_500_content
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>Server Error (500)</title>
          <meta charset="utf-8">
          <style>
            body { font-family: system-ui, sans-serif; color: #333; text-align: center; padding: 100px 20px; }
            h1 { font-size: 3em; margin-bottom: 10px; color: #dc2626; }
            p { font-size: 1.2em; color: #666; }
          </style>
        </head>
        <body>
          <h1>500</h1>
          <p>An internal server error occurred.</p>
          <p>Please try again later.</p>
        </body>
        </html>
      HTML
    end

    def development_config_content
      <<~RUBY
        # Development configuration
        Salvia.logger = Logger.new(STDOUT)
        Salvia.logger.level = Logger::DEBUG
      RUBY
    end

    def production_config_content
      <<~RUBY
        # Production configuration
        log_dir = File.join(Salvia.root, "log")
        Dir.mkdir(log_dir) unless Dir.exist?(log_dir)

        Salvia.logger = Logger.new(File.join(log_dir, "production.log"))
        Salvia.logger.level = Logger::INFO
      RUBY
    end

    def islands_js_content
      <<~JS
        // Salvia Islands - Client-side hydration
        import { h, render, hydrate } from 'https://esm.sh/preact@10.19.3';
        import htm from 'https://esm.sh/htm@3.1.1';

        const html = htm.bind(h);

        // Mount Island components
        document.addEventListener('DOMContentLoaded', async () => {
          const islands = document.querySelectorAll('[data-island]');
          
          for (const island of islands) {
            const name = island.dataset.island;
            const props = JSON.parse(island.dataset.props || '{}');
            
            try {
              // Dynamic import from /islands/
              const module = await import(`/islands/${name}.js`);
              const Component = module[name] || module.default;
              
              if (Component) {
                // Hydrate if SSR content exists, otherwise render
                if (island.innerHTML.trim()) {
                  hydrate(html`<\${Component} ...\${props} />`, island);
                } else {
                  render(html`<\${Component} ...\${props} />`, island);
                }
                console.log(`🏝️ Island mounted: \${name}`);
              } else {
                console.error(`Island component \${name} not found in module`);
              }
            } catch (error) {
              console.error(`Failed to load island: \${name}`, error);
            }
          }
        });
      JS
    end

    def build_ssr_ts_content
      <<~TS
        #!/usr/bin/env -S deno run --allow-all
        /**
         * Salvia Island SSR Build Script
         * 
         * 使用方法:
         *   deno run --allow-all bin/build_ssr.ts
         *   deno run --allow-all bin/build_ssr.ts --watch
         */

        import * as esbuild from "https://deno.land/x/esbuild@v0.24.2/mod.js";
        import { denoPlugins } from "jsr:@luca/esbuild-deno-loader@0.11";

        const ISLANDS_DIR = "./app/islands";
        const OUTPUT_FILE = "./vendor/server/ssr_bundle.js";
        const WATCH_MODE = Deno.args.includes("--watch");
        const VERBOSE = Deno.args.includes("--verbose");

        async function findIslandFiles(): Promise<string[]> {
          const files: string[] = [];
          try {
            for await (const entry of Deno.readDir(ISLANDS_DIR)) {
              if (entry.isFile && (entry.name.endsWith(".tsx") || entry.name.endsWith(".jsx") || entry.name.endsWith(".js"))) {
                files.push(`\${ISLANDS_DIR}/\${entry.name}`);
              }
            }
          } catch {
            console.log("📁 app/islands ディレクトリが見つかりません。スキップします。");
          }
          return files;
        }

        async function build() {
          const entryPoints = await findIslandFiles();
          
          if (entryPoints.length === 0) {
            console.log("⚠️  Island コンポーネントが見つかりません。");
            return;
          }

          if (VERBOSE) {
            console.log("🔍 ビルド対象:", entryPoints);
          }

          // SSR 用のバンドルを生成
          const result = await esbuild.build({
            entryPoints,
            bundle: true,
            format: "esm",
            outfile: OUTPUT_FILE,
            platform: "neutral",
            plugins: [...denoPlugins()],
            external: [],
            define: {
              "typeof window": '"undefined"',
            },
            banner: {
              js: `// Salvia SSR Bundle - Generated at \${new Date().toISOString()}
        globalThis.SalviaSSR = globalThis.SalviaSSR || {};`,
            },
            footer: {
              js: `
        // Export all components to globalThis.SalviaSSR
        // Components are automatically registered`,
            },
          });

          if (result.errors.length > 0) {
            console.error("❌ ビルドエラー:", result.errors);
          } else {
            console.log(\`✅ SSR バンドル生成完了: \${OUTPUT_FILE}\`);
          }
        }

        async function watch() {
          console.log("👀 Island コンポーネントの変更を監視中...");
          
          const watcher = Deno.watchFs(ISLANDS_DIR);
          let debounceTimer: number | undefined;
          
          for await (const event of watcher) {
            if (event.kind === "modify" || event.kind === "create") {
              clearTimeout(debounceTimer);
              debounceTimer = setTimeout(async () => {
                console.log("🔄 変更を検出、リビルド中...");
                await build();
              }, 100);
            }
          }
        }

        // メイン実行
        console.log("🏝️  Salvia Island SSR Builder");
        await build();

        if (WATCH_MODE) {
          await watch();
        } else {
          await esbuild.stop();
        }
      TS
    end
  end
end
