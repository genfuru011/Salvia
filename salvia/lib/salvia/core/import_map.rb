# frozen_string_literal: true

require "json"

module Salvia
  module Core
    class ImportMap
    def self.load
      new.load
    end

    def load
      path = find_deno_json
      return {} unless path

      begin
        content = File.read(path)
        json = JSON.parse(content)
        json["imports"] || {}
      rescue JSON::ParserError
        {}
      end
    end

    def keys
      load.keys
    end

    private

    def find_deno_json
      Salvia.config.deno_config_path
    end
    end
  end
end
