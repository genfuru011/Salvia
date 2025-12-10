Salvia.configure do |config|
  config.islands_dir = Rails.root.join("app/islands")
  config.build_dir = Rails.root.join("public/assets")
  config.ssr_bundle_path = Rails.root.join("salvia/server/ssr_bundle.js")
end

# Initialize SSR Engine
Salvia::SSR.configure(
  bundle_path: Salvia.config.ssr_bundle_path,
  development: Rails.env.development?
)
