require "bundler/setup"
require "sage"

# Load all models
Dir[File.join(__dir__, "../app/models/**/*.rb")].each { |f| require f }

# Load all resources
Dir[File.join(__dir__, "../app/resources/**/*.rb")].each { |f| require f }

class App < Sage::Base
  # Middleware
  use Rack::CommonLogger
  use Sage::Middleware::ConnectionManagement
  use Sage::Middleware::SidecarManager
  use Sage::Middleware::AssetProxy
  
  # Mount Resources
  mount "/", HomeResource
end
