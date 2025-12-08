require "bundler/setup"
require "salvia_rb"

# アプリケーションルートを設定
Salvia.root = File.expand_path("..", __dir__)

# データベース設定を読み込み
Salvia::Database.setup!

# 環境設定を読み込み
Salvia.load_config

# Zeitwerk オートローダー設定
loader = Zeitwerk::Loader.new
loader.push_dir(File.join(Salvia.root, "app", "controllers"))
loader.push_dir(File.join(Salvia.root, "app", "models"))
loader.push_dir(File.join(Salvia.root, "app", "components"))
loader.enable_reloading if Salvia.development?
loader.setup
Salvia.app_loader = loader

# ルーティングを読み込み
require_relative "routes"

# Import Map を読み込み
require_relative "importmap"
