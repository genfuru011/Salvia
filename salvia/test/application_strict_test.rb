# frozen_string_literal: true

require_relative "test_helper"

class ApplicationStrictTest < Minitest::Test
  def with_temp_app
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield Pathname.new(dir)
      end
    end
  end

  def write_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def minimal_routes
    <<~RUBY
      Salvia::Router.draw do
        root to: "home#index"
      end
    RUBY
  end

  def minimal_db_yml
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
        <<: *default
        database: db/production.sqlite3
    YAML
  end

  def test_requires_config_app
    ENV["RACK_ENV"] = "development"
    reset_salvia!

    with_temp_app do |root|
      write_file(root.join("config/routes.rb"), minimal_routes)
      FileUtils.mkdir_p(root.join("db"))
      # intentionally omit config/app.rb

      error = assert_raises(Salvia::Error) { Salvia::Application.new }
      assert_includes error.message, "config/app.rb"
    end
  ensure
    reset_salvia!
  end

  def test_requires_database_yml
    ENV["RACK_ENV"] = "development"
    reset_salvia!

    with_temp_app do |root|
      write_file(root.join("config/app.rb"), <<~RUBY)
        Salvia.configure do |config|
          config.secret_key = "dev-key"
        end
      RUBY
      write_file(root.join("config/routes.rb"), minimal_routes)
      FileUtils.mkdir_p(root.join("db"))
      # omit database.yml

      error = assert_raises(Salvia::Error) { Salvia::Application.new }
      assert_includes error.message, "config/database.yml"
    end
  ensure
    reset_salvia!
  end

  def test_requires_db_directory
    ENV["RACK_ENV"] = "development"
    reset_salvia!

    with_temp_app do |root|
      write_file(root.join("config/app.rb"), <<~RUBY)
        Salvia.configure do |config|
          config.secret_key = "dev-key"
        end
      RUBY
      write_file(root.join("config/routes.rb"), minimal_routes)
      write_file(root.join("config/database.yml"), minimal_db_yml)
      # intentionally do NOT create db/

      error = assert_raises(Salvia::Error) { Salvia::Application.new }
      assert_includes error.message, "db directory"
    end
  ensure
    reset_salvia!
  end

  def test_boots_with_all_required_configs
    ENV["RACK_ENV"] = "development"
    reset_salvia!

    with_temp_app do |root|
      write_file(root.join("config/app.rb"), <<~RUBY)
        Salvia.configure do |config|
          config.secret_key = "dev-key"
          config.cache_templates = false
        end
      RUBY
      write_file(root.join("config/routes.rb"), minimal_routes)
      write_file(root.join("config/database.yml"), minimal_db_yml)
      FileUtils.mkdir_p(root.join("db"))

      app = nil
      assert_silent { app = Salvia::Application.new }
      assert_instance_of Salvia::Application, app
    end
  ensure
    reset_salvia!
  end

  def test_requires_secret_key_in_production
    ENV["RACK_ENV"] = "production"
    reset_salvia!

    with_temp_app do |root|
      write_file(root.join("config/app.rb"), <<~RUBY)
        Salvia.configure do |config|
          # missing secret_key on purpose
        end
      RUBY
      write_file(root.join("config/routes.rb"), minimal_routes)
      write_file(root.join("config/database.yml"), minimal_db_yml)
      FileUtils.mkdir_p(root.join("db"))

      error = assert_raises(Salvia::Error) { Salvia::Application.new }
      assert_includes error.message, "SECRET_KEY"
    end
  ensure
    reset_salvia!
  end
end
