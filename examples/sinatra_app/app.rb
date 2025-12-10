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

# Serve client-side island components
get "/client/:name.js" do
  content_type "application/javascript"
  file_path = File.join(__dir__, "vendor/client/#{params[:name]}.js")
  if File.exist?(file_path)
    send_file file_path
  else
    halt 404
  end
end

get "/" do
  erb :index
end
