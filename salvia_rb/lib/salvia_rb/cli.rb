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
      
      script_path = build_script_path
      cmd = "deno run --allow-all #{script_path}"
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
      
      script_path = build_script_path
      cmd = "deno run --allow-all #{script_path} --watch"
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
        deno_pid = spawn("deno run --allow-all #{build_script_path} --watch",
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

    # gem 内蔵のビルドスクリプトパスを返す
    def build_script_path
      File.expand_path("../../../assets/scripts/build_ssr.ts", __FILE__)
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

      # 設定 (最小構成)
      empty_directory "#{@app_name}/config"
      # empty_directory "#{@app_name}/config/environments"  # オプション

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

      # config.ru (ゼロコンフィグ - たった3行)
      create_file "#{@app_name}/config.ru", config_ru_content

      # config/routes.rb (これだけ必須)
      create_file "#{@app_name}/config/routes.rb", routes_rb_content

      # config/environment.rb (アプリ起動ポイント)
      create_file "#{@app_name}/config/environment.rb", environment_rb_content

      # config/database.yml (オプション - なくても動作)
      unless @template == "minimal"
        create_file "#{@app_name}/config/database.yml", database_yml_content
      end

      # config/environments (オプション - カスタマイズ用)
      # create_file "#{@app_name}/config/environments/development.rb", development_config_content
      # create_file "#{@app_name}/config/environments/production.rb", production_config_content

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

      # Docker (本番環境用)
      create_file "#{@app_name}/Dockerfile", dockerfile_content
      create_file "#{@app_name}/docker-compose.yml", docker_compose_content
      create_file "#{@app_name}/.dockerignore", dockerignore_content
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

      # Islands コンポーネント
      if @include_islands
        create_file "#{@app_name}/app/islands/Counter.js", counter_island_content
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

      # SSR 用ディレクトリ - Islands を含む場合のみ
      if @include_islands
        empty_directory "#{@app_name}/vendor/server"
      end
    end

    # ファイルコンテンツメソッド
    def gemfile_content
      <<~RUBY
        source "https://rubygems.org"

        gem "salvia_rb"
        gem "sqlite3"

        # Web サーバー
        gem "puma"    # 開発環境用 (スレッドベース)
        gem "falcon"  # 本番環境用 (async/fork、Linux/Docker推奨)

        # 本番環境用データベース (Docker/PostgreSQL)
        gem "pg", "~> 1.6"

        group :development do
          gem "debug"
        end
      RUBY
    end

    def config_ru_content
      <<~RUBY
        # Salvia - ゼロコンフィグで動作
        # すべての設定は Application.new 内で自動処理されます
        require "bundler/setup"
        require "salvia_rb"

        run Salvia::Application.new
      RUBY
    end

    def environment_rb_content
      <<~RUBY
        # 環境固有の設定（オプション）
        #
        # このファイルは任意です。Salvia はゼロコンフィグで動作します。
        # カスタマイズが必要な場合のみ編集してください。
        #
        # require "bundler/setup"
        # require "salvia_rb"
        #
        # Salvia.configure do |config|
        #   config.ssr_bundle_path = "vendor/server/ssr_bundle.js"
        # end
      RUBY
    end

    def environment_rb_content
      <<~RUBY
        # frozen_string_literal: true

        require "bundler/setup"
        require "salvia_rb"

        # アプリケーション初期化
        Salvia.root = File.expand_path("..", __dir__)
        Salvia.env = ENV.fetch("RACK_ENV", "development")

        # ルートを読み込み
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
        # データベース設定（オプション）
        #
        # このファイルは任意です。なくても Salvia は以下の規約で動作します:
        #   development: db/development.sqlite3
        #   test: db/test.sqlite3
        #   production: DATABASE_URL 環境変数、または db/production.sqlite3
        #
        # PostgreSQL を使う場合のみ本番環境を設定してください:
        #
        # production:
        #   adapter: postgresql
        #   url: <%= ENV["DATABASE_URL"] %>

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
          <<: *default
          database: db/production.sqlite3
          # または PostgreSQL:
          # adapter: postgresql
          # url: <%= ENV["DATABASE_URL"] %>
      YAML
    end

    def rakefile_content
      <<~RUBY
        # Salvia Rakefile - ゼロコンフィグ
        require "bundler/setup"
        require "salvia_rb"

        # アプリケーションルートを設定
        Salvia.root = File.expand_path(__dir__)

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
            Salvia::Database.setup!
            Salvia::Database.migrate!
          end

          desc "直前のマイグレーションをロールバック"
          task :rollback do
            Salvia::Database.setup!
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

        # ビルド出力
        /public/assets/stylesheets/tailwind.css
        /vendor/server/
        /vendor/client/

        # OS ファイル
        .DS_Store

        # IDE
        .idea/
        .vscode/
      TEXT
    end

    def dockerfile_content
      # アプリ名からベース名のみを抽出
      safe_app_name = File.basename(@app_name).gsub(/[^a-zA-Z0-9_-]/, "_").downcase

      <<~DOCKERFILE
        # Salvia Production Dockerfile
        # Falcon (async server) + YJIT enabled
        FROM ruby:3.2.9-slim

        # 環境変数
        ENV RUBY_YJIT_ENABLE=1
        ENV RACK_ENV=production
        ENV BUNDLE_WITHOUT=development:test
        ENV BUNDLE_DEPLOYMENT=1

        # システム依存パッケージ
        RUN apt-get update -qq && \\
            apt-get install -y --no-install-recommends \\
            build-essential \\
            libpq-dev \\
            nodejs \\
            curl \\
            && rm -rf /var/lib/apt/lists/*

        # 作業ディレクトリ
        WORKDIR /app

        # Gemfile コピーと依存関係インストール
        COPY Gemfile Gemfile.lock ./
        RUN bundle install --jobs 4 --retry 3

        # アプリケーションコード
        COPY . .

        # アセットのビルド (Tailwind CSS)
        RUN bundle exec rake css:build || true

        # 非 root ユーザーで実行
        RUN useradd -m -s /bin/bash appuser && \\
            chown -R appuser:appuser /app
        USER appuser

        # ポート公開
        EXPOSE 9292

        # Falcon で起動 (YJIT 有効)
        CMD ["bundle", "exec", "falcon", "serve", "--bind", "http://0.0.0.0:9292", "--count", "4"]
      DOCKERFILE
    end

    def docker_compose_content
      # アプリ名からベース名のみを抽出
      safe_app_name = File.basename(@app_name).gsub(/[^a-zA-Z0-9_-]/, "_").downcase

      <<~YAML
        # Salvia Docker Compose Configuration
        # Production environment with PostgreSQL

        services:
          db:
            image: postgres:15-alpine
            volumes:
              - postgres_data:/var/lib/postgresql/data
            environment:
              POSTGRES_DB: #{safe_app_name}_production
              POSTGRES_USER: #{safe_app_name}
              POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-changeme}
            healthcheck:
              test: ["CMD-SHELL", "pg_isready -U #{safe_app_name}"]
              interval: 5s
              timeout: 5s
              retries: 5

          app:
            build: .
            ports:
              - "9292:9292"
            environment:
              RACK_ENV: production
              DATABASE_URL: postgres://#{safe_app_name}:\${POSTGRES_PASSWORD:-changeme}@db:5432/#{safe_app_name}_production
              SESSION_SECRET: \${SESSION_SECRET:-generate_a_secure_secret_here}
              RUBY_YJIT_ENABLE: "1"
            depends_on:
              db:
                condition: service_healthy
            # ヘルスチェック
            healthcheck:
              test: ["CMD", "curl", "-f", "http://localhost:9292/"]
              interval: 30s
              timeout: 10s
              retries: 3

        volumes:
          postgres_data:
      YAML
    end

    def dockerignore_content
      <<~TEXT
        # Git
        .git
        .gitignore

        # ドキュメント
        *.md
        docs/

        # 開発用ファイル
        .env.local
        .env.development

        # テスト
        test/
        spec/

        # ログとデータベース
        log/
        db/*.sqlite3

        # 一時ファイル
        tmp/
        .DS_Store

        # Bundler (Docker 内で再インストール)
        vendor/bundle/
        .bundle/

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
      if @include_islands
        home_index_with_islands_content
      else
        home_index_basic_content
      end
    end

    def home_index_with_islands_content
      <<~ERB
        <div class="max-w-2xl mx-auto mt-16 px-4">
          <div class="text-center">
            <h1 class="text-4xl font-bold text-salvia-700 mb-4">
              🌿 Salvia へようこそ
            </h1>
            <p class="text-lg text-slate-600 mb-8">
              小さくて理解しやすい Ruby MVC フレームワーク
            </p>

            <!-- SSR Islands Demo -->
            <div class="mb-8">
              <h2 class="text-xl font-semibold mb-4">🏝️ SSR Islands Demo</h2>
              <div class="flex justify-center">
                <%= island "Counter", initialCount: 0 %>
              </div>
              <p class="text-xs text-slate-500 mt-2">
                ↑ Preact で動くインタラクティブコンポーネント
              </p>
            </div>

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
                    <code class="bg-slate-100 px-2 py-1 rounded">app/islands/</code>
                    <p class="text-slate-600 mt-1">Islands コンポーネントを追加</p>
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

    def home_index_basic_content
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
                    <p class="text-slate-600 mt-1">ERB でビューを作成</p>
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

    def counter_island_content
      <<~JS
        // Counter Island - インタラクティブカウンター
        import { h, render, hydrate } from 'https://esm.sh/preact@10.19.3';
        import { useState } from 'https://esm.sh/preact@10.19.3/hooks';
        import htm from 'https://esm.sh/htm@3.1.1';

        const html = htm.bind(h);

        export default function Counter({ initialCount = 0 }) {
          const [count, setCount] = useState(initialCount);

          return html`
            <div class="p-6 bg-white rounded-lg shadow-md">
              <h3 class="text-lg font-semibold mb-3 text-salvia-700">🏝️ Counter Island</h3>
              <p class="text-4xl font-bold text-salvia-600 mb-4">\${count}</p>
              <div class="flex gap-2 justify-center">
                <button
                  onClick=\${() => setCount(count - 1)}
                  class="px-4 py-2 bg-slate-200 rounded hover:bg-slate-300 transition"
                >−</button>
                <button
                  onClick=\${() => setCount(0)}
                  class="px-4 py-2 bg-slate-100 rounded hover:bg-slate-200 transition"
                >Reset</button>
                <button
                  onClick=\${() => setCount(count + 1)}
                  class="px-4 py-2 bg-salvia-500 text-white rounded hover:bg-salvia-600 transition"
                >+</button>
              </div>
            </div>
          `;
        }

        // Salvia mount function
        export function mount(element, props, { hydrate: shouldHydrate } = {}) {
          const vnode = html`<\${Counter} ...\${props} />`;
          shouldHydrate ? hydrate(vnode, element) : render(vnode, element);
        }

        export { Counter };
      JS
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
        #
        # 推奨サーバー: Puma (スレッドベース、macOS との互換性良好)
        #   bundle exec puma -p 9292
        #
        Salvia.logger = Logger.new(STDOUT)
        Salvia.logger.level = Logger::DEBUG
      RUBY
    end

    def production_config_content
      <<~RUBY
        # Production configuration
        #
        # 推奨サーバー: Falcon (async/fork、高パフォーマンス)
        #   bundle exec falcon serve --bind http://0.0.0.0:9292
        #
        # 注意: macOS + PostgreSQL 環境では Falcon は fork の問題があります。
        #       本番環境では Docker (Linux) を使用してください。
        #
        # Docker での起動:
        #   docker-compose up --build
        #
        # YJIT の有効化 (Ruby 3.2+):
        #   export RUBY_YJIT_ENABLE=1
        #
        log_dir = File.join(Salvia.root, "log")
        Dir.mkdir(log_dir) unless Dir.exist?(log_dir)

        Salvia.logger = Logger.new(File.join(log_dir, "production.log"))
        Salvia.logger.level = Logger::INFO
      RUBY
    end

    def islands_js_content
      # gem assets からコピー
      assets_path = File.expand_path("../../../assets/javascripts/islands.js", __FILE__)
      File.read(assets_path)
    end
  end
end
