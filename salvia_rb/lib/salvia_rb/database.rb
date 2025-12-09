# frozen_string_literal: true

require "active_record"
require "yaml"
require "erb"

module Salvia
  # ActiveRecord を使用したデータベース接続管理
  #
  # ゼロコンフィグ対応: config/database.yml がなくても動作
  #
  # @example 規約ベースのデフォルト
  #   # config/database.yml なしで自動的に以下を使用:
  #   # development: db/development.sqlite3
  #   # test: db/test.sqlite3
  #   # production: DATABASE_URL または db/production.sqlite3
  #
  class Database
    class << self
      # データベース接続をセットアップ
      #
      # @param env [String] 環境名（デフォルト: Salvia.env）
      def setup!(env = nil)
        env ||= Salvia.env
        config = load_config(env)

        ActiveRecord::Base.establish_connection(config)

        # 開発環境では SQL をログ出力
        if Salvia.development?
          ActiveRecord::Base.logger = Logger.new($stdout)
        end
      end

      # config/database.yml からデータベース設定を読み込み
      # ファイルがなければ規約ベースのデフォルトを使用
      #
      # @param env [String] 環境名
      # @return [Hash] データベース設定
      def load_config(env)
        config_path = File.join(Salvia.root, "config", "database.yml")

        if File.exist?(config_path)
          load_config_from_file(config_path, env)
        else
          default_config(env)
        end
      end

      # 規約ベースのデフォルト設定
      def default_config(env)
        # 本番環境で DATABASE_URL があればそれを使用
        if env.to_s == "production" && ENV["DATABASE_URL"]
          return { "url" => ENV["DATABASE_URL"] }
        end

        # SQLite デフォルト
        db_dir = File.join(Salvia.root, "db")
        FileUtils.mkdir_p(db_dir)

        {
          "adapter" => "sqlite3",
          "database" => File.join(db_dir, "#{env}.sqlite3"),
          "pool" => 5,
          "timeout" => 5000
        }
      end

      private

      def load_config_from_file(config_path, env)
        yaml_content = ERB.new(File.read(config_path)).result
        config = YAML.safe_load(yaml_content, aliases: true)
        config[env] || config[env.to_s] || default_config(env)
      end

      public

      # データベースを作成
      def create!(env = nil)
        env ||= Salvia.env
        config = load_config(env)

        case config["adapter"]
        when "sqlite3"
          # SQLite はファイルを自動作成
          db_path = config["database"]
          FileUtils.mkdir_p(File.dirname(db_path)) if db_path != ":memory:"
          puts "データベースを作成しました: #{db_path}"
        when "postgresql"
          create_postgresql_database(config)
        when "mysql2"
          create_mysql_database(config)
        else
          raise Error, "不明なアダプター: #{config['adapter']}"
        end
      end

      # データベースを削除
      def drop!(env = nil)
        env ||= Salvia.env
        config = load_config(env)

        case config["adapter"]
        when "sqlite3"
          db_path = config["database"]
          if File.exist?(db_path)
            File.delete(db_path)
            puts "データベースを削除しました: #{db_path}"
          end
        when "postgresql"
          drop_postgresql_database(config)
        when "mysql2"
          drop_mysql_database(config)
        end
      end

      # 保留中のマイグレーションを実行
      def migrate!
        migrations_path = File.join(Salvia.root, "db", "migrate")
        ActiveRecord::MigrationContext.new(migrations_path).migrate
      end

      # 直前のマイグレーションをロールバック
      def rollback!(steps = 1)
        migrations_path = File.join(Salvia.root, "db", "migrate")
        ActiveRecord::MigrationContext.new(migrations_path).rollback(steps)
      end

      # マイグレーションの状態を取得
      def migration_status
        migrations_path = File.join(Salvia.root, "db", "migrate")
        context = ActiveRecord::MigrationContext.new(migrations_path)

        {
          pending: context.migrations.select { |m| !context.current_version || m.version > context.current_version }.map(&:version),
          current: context.current_version
        }
      end

      private

      def create_postgresql_database(config)
        ActiveRecord::Base.establish_connection(config.merge("database" => "postgres"))
        ActiveRecord::Base.connection.create_database(config["database"], config)
        puts "データベースを作成しました: #{config['database']}"
      rescue ActiveRecord::DatabaseAlreadyExists
        puts "データベースは既に存在します: #{config['database']}"
      end

      def drop_postgresql_database(config)
        ActiveRecord::Base.establish_connection(config.merge("database" => "postgres"))
        ActiveRecord::Base.connection.drop_database(config["database"])
        puts "データベースを削除しました: #{config['database']}"
      rescue ActiveRecord::NoDatabaseError
        puts "データベースが存在しません: #{config['database']}"
      end

      def create_mysql_database(config)
        ActiveRecord::Base.establish_connection(config.merge("database" => nil))
        ActiveRecord::Base.connection.create_database(config["database"], config)
        puts "データベースを作成しました: #{config['database']}"
      rescue ActiveRecord::DatabaseAlreadyExists
        puts "データベースは既に存在します: #{config['database']}"
      end

      def drop_mysql_database(config)
        ActiveRecord::Base.establish_connection(config.merge("database" => nil))
        ActiveRecord::Base.connection.drop_database(config["database"])
        puts "データベースを削除しました: #{config['database']}"
      rescue ActiveRecord::NoDatabaseError
        puts "データベースが存在しません: #{config['database']}"
      end
    end
  end
end
