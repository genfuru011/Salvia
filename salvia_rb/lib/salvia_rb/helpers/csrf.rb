# frozen_string_literal: true

module Salvia
  module Helpers
    # CSRF 保護用ヘルパー
    module CSRF
      # CSRF トークンを取得
      #
      # @return [String] CSRF トークン
      #
      # @example
      #   <input type="hidden" name="authenticity_token" value="<%= csrf_token %>">
      #
      def csrf_token
        Salvia::CSRF.token(session)
      end

      # CSRF meta タグを生成
      #
      # @return [String] meta タグ HTML
      #
      # @example
      #   <head>
      #     <%= csrf_meta_tag %>
      #   </head>
      #
      def csrf_meta_tag
        %(<meta name="csrf-token" content="#{csrf_token}">)
      end
      alias csrf_meta_tags csrf_meta_tag

      # CSRF hidden input を生成
      #
      # @return [String] hidden input HTML
      #
      # @example
      #   <form method="post">
      #     <%= csrf_field %>
      #     ...
      #   </form>
      #
      def csrf_field
        %(<input type="hidden" name="authenticity_token" value="#{csrf_token}">)
      end
    end
  end
end
