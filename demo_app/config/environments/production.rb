Salvia.configure do |config|
  # 本番環境の設定
  # log ディレクトリがない場合は作成
  log_dir = File.join(Salvia.root, "log")
  Dir.mkdir(log_dir) unless Dir.exist?(log_dir)

  config.logger = Logger.new(File.join(log_dir, "production.log"))
  config.logger.level = Logger::INFO
end
