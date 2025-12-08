# frozen_string_literal: true

module Salvia
  module Helpers
    module ImportMap
      # Import Map タグを生成する
      #
      # @return [String] <script type="importmap">...</script>
      def importmap_tags
        map_json = Salvia.importmap.to_json
        
        # ES Module Shims (古いブラウザ互換性のため)
        shims = '<script async src="https://ga.jspm.io/npm:es-module-shims@1.8.2/dist/es-module-shims.js"></script>'
        
        "#{shims}\n<script type=\"importmap\">\n#{map_json}\n</script>"
      end
    end
  end
end
