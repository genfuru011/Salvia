# frozen_string_literal: true

require "json"
require "digest"
require "fileutils"
require "pathname"

module Salvia
  module Assets
    MANIFEST_PATH = "public/assets/manifest.json"

    class << self
      def path(source)
        return "/assets/#{source}" if Salvia.development? || Salvia.test?

        manifest[source] || "/assets/#{source}"
      end

      def manifest
        @manifest ||= load_manifest
      end

      def load_manifest
        path = File.join(Salvia.root, MANIFEST_PATH)
        if File.exist?(path)
          JSON.parse(File.read(path))
        else
          {}
        end
      end

      # マニフェストをリセット（テスト用など）
      def reset!
        @manifest = nil
      end

      # アセットのプリコンパイル（CLI用）
      def precompile!
        manifest = {}
        assets_dir = File.join(Salvia.root, "public", "assets")
        target_dir = assets_dir # 同じディレクトリにハッシュ付きファイルを置く

        Dir.glob("#{assets_dir}/**/*").each do |file|
          next if File.directory?(file)
          next if file.end_with?(".json") # マニフェスト自体はスキップ
          next if File.basename(file).match?(/^[a-f0-9]{64}\./) # 既にハッシュ付きならスキップ（簡易判定）

          # 相対パスを取得 (e.g., "stylesheets/tailwind.css")
          relative_path = Pathname.new(file).relative_path_from(Pathname.new(assets_dir)).to_s
          
          # ハッシュ計算
          content = File.read(file)
          hash = Digest::SHA256.hexdigest(content)[0...8]
          ext = File.extname(file)
          basename = File.basename(file, ext)
          
          hashed_filename = "#{basename}-#{hash}#{ext}"
          hashed_relative_path = File.join(File.dirname(relative_path), hashed_filename)
          
          # ファイルコピー
          FileUtils.cp(file, File.join(target_dir, hashed_relative_path))
          
          # マニフェストに追加
          # key: "stylesheets/tailwind.css", value: "/assets/stylesheets/tailwind-123...css"
          manifest[relative_path] = "/assets/#{hashed_relative_path}"
        end

        # マニフェスト保存
        File.write(File.join(Salvia.root, MANIFEST_PATH), JSON.pretty_generate(manifest))
        puts "✨ Assets precompiled to #{MANIFEST_PATH}"
      end
    end
  end
end
