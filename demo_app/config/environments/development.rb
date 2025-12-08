Salvia.configure do |config|
  # 開発環境の設定
  config.logger = Logger.new(File.join(Salvia.root, "log", "development.log"))
  config.logger.level = Logger::DEBUG
end
