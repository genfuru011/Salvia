require "bundler/setup"
require "sage"
require "salvia"

# Load Salvia configuration
require_relative "salvia" if File.exist?(File.join(__dir__, "salvia.rb"))

# Load all resources
Dir[File.join(__dir__, "../app/resources/**/*.rb")].each { |f| require f }

class App < Sage::Base
  # Middleware
  use Rack::CommonLogger
  
  # Mount Resources
  mount "/", HomeResource
end
