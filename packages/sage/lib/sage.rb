require_relative "sage/version"
require_relative "sage/server"
require_relative "sage/base"
require_relative "sage/resource"
require_relative "sage/generator"
require_relative "sage/middleware/connection_management"

module Sage
  class Error < StandardError; end
end
