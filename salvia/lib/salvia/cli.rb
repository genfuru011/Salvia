# frozen_string_literal: true

require "thor"
require "fileutils"

module Salvia
  class CLI < Thor
    include Thor::Actions

    def self.source_root
      File.expand_path("../../..", __FILE__)
    end

    desc "install", "Install Salvia SSR files into your application"
    def install
      say "🌿 Installing Salvia SSR...", :green

      # Create directories
      empty_directory "app/islands"
      empty_directory "public/assets/javascripts"
      empty_directory "public/assets/islands"
      empty_directory "salvia"

      # Copy files
      # Note: source_root is 'salvia/', so paths are relative to that
      copy_file "assets/scripts/deno.json", "salvia/deno.json"
      copy_file "assets/scripts/build.ts", "salvia/build.ts"
      copy_file "assets/javascripts/islands.js", "public/assets/javascripts/islands.js"

      chmod "salvia/build.ts", 0755

      say ""
      say "✅ Salvia SSR installed!", :green
      say "   - app/islands/           : Put your .jsx components here"
      say "   - salvia/build.ts        : Build script"
      say "   - salvia/deno.json       : Deno configuration"
      say ""
      say "Next steps:", :yellow
      say "  1. Install Deno: https://deno.land"
      say "  2. Run build: salvia build"
    end

    desc "build", "Build Island components for SSR"
    method_option :verbose, aliases: "-v", type: :boolean, default: false, desc: "Verbose output"
    def build
      check_deno_installed!
      
      say "🏝️  Building Island components...", :green
      
      # Use deno task defined in salvia/deno.json
      cmd = "deno task --config salvia/deno.json build"
      cmd += " --verbose" if options[:verbose]
      
      success = system(cmd)
      
      if success
        say "✅ SSR build completed!", :green
      else
        say "❌ SSR build failed", :red
        say "Make sure you have run 'salvia install' and have a salvia/deno.json file.", :yellow
        exit 1
      end
    end

    desc "watch", "Watch and rebuild Island components"
    method_option :verbose, aliases: "-v", type: :boolean, default: false, desc: "Verbose output"
    def watch
      check_deno_installed!
      
      say "👀 Watching Island components...", :green
      
      cmd = "deno task --config salvia/deno.json watch"
      cmd += " --verbose" if options[:verbose]
      
      exec cmd
    end

    desc "version", "Display Salvia version"
    def version
      require "salvia/version"
      say "Salvia #{Salvia::VERSION}"
    end

    private

    def check_deno_installed!
      unless system("which deno > /dev/null 2>&1")
        say "❌ Deno is not installed.", :red
        say "Please install Deno: https://deno.land", :yellow
        exit 1
      end
    end
  end
end
