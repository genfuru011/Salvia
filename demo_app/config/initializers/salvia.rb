Salvia.configure do |config|
  config.islands_dir = Rails.root.join("salvia/app/islands")
  config.build_dir = Rails.root.join("public/assets")
  config.ssr_bundle_path = Rails.root.join("salvia/server/ssr_bundle.js")
end
