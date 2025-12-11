# frozen_string_literal: true

module Salvia
  module Core
    class Configuration
      attr_accessor :ssr_bundle_path, :island_inspector, :islands_dir, :build_dir, :deno_config_path, :root

      def initialize
        @root = Dir.pwd
        @ssr_bundle_path = "salvia/server/ssr_bundle.js"
        @islands_dir = "salvia/app/islands"
        @build_dir = "public/assets"
        
        user_deno_json = File.join(@root, "salvia/deno.json")
        if File.exist?(user_deno_json)
          @deno_config_path = user_deno_json
        else
          @deno_config_path = File.expand_path("../../../assets/scripts/deno.json", __dir__)
        end
        
        @island_inspector = nil
      end

      def island_inspector?
        return @island_inspector unless @island_inspector.nil?
        Salvia.development?
      end
    end
  end
end
