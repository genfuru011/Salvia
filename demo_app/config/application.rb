require "bundler/setup"
require "sage"
require "salvia"
require "fileutils"

require_relative "../config/database"
require_relative "../app/models/todo"

# Load all resources
Dir[File.join(__dir__, "../app/resources/**/*.rb")].each { |f| require f }

class App < Sage::Base
  # Middleware
  use Rack::CommonLogger
  use Sage::Middleware::ConnectionManagement
  
  # Mount Resources
  mount "/", HomeResource
  mount "/todos", TodosResource
end
