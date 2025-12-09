# frozen_string_literal: true

module Salvia
  module Helpers
    include Tag
    include Component
    include ImportMap
    include Island
    include Inspector

    # HTMX ヘルパーはプラグイン有効時のみ動的に含まれる
    # 後方互換性のため、明示的に include された場合は警告を出す
  end
end
