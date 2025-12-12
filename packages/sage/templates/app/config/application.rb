require "bundler/setup"
require "sage"
require "salvia"

# Load all resources
Dir[File.join(__dir__, "../app/resources/**/*.rb")].each { |f| require f }

class App < Sage::Base
  # Middleware
  use Rack::CommonLogger
  
  # Mount Resources
  mount "/", HomeResource
end
