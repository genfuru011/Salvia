require "sinatra"
require "salvia"

# Configure Salvia
Salvia.configure do |config|
  config.islands_dir = File.join(__dir__, "app/islands")
  config.build_dir = File.join(__dir__, "public/assets")
  config.ssr_bundle_path = File.join(__dir__, "vendor/server/ssr_bundle.js")
end

# Initialize SSR Engine
Salvia::SSR.configure(
  bundle_path: Salvia.config.ssr_bundle_path,
  development: true
)

helpers Salvia::Helpers

get "/" do
  erb :index
end
