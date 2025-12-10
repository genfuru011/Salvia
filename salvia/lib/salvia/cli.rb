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
    method_option :tailwind, type: :boolean, desc: "Generate Tailwind CSS configuration"
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
      
      create_file "salvia/.gitignore", "/server/\n"

      # Tailwind CSS setup
      install_tailwind = options[:tailwind]
      if install_tailwind.nil?
        install_tailwind = yes?("🎨 Do you want to install Tailwind CSS? (y/N)", :yellow)
      end

      if install_tailwind
        # Add tailwindcss-ruby to Gemfile if present
        if File.exist?("Gemfile")
          append_to_file "Gemfile", "\ngem 'tailwindcss-ruby'\n"
          say "   - Added 'tailwindcss-ruby' to Gemfile"
        end

        empty_directory "app/assets/stylesheets"
        create_file "app/assets/stylesheets/application.tailwind.css" do
          <<~CSS
            @import "tailwindcss";

            @source "../../views/**/*.erb";
            @source "../../islands/**/*.{js,jsx,tsx}";
            @source "../../../public/assets/javascripts/**/*.js";

            @theme {
              --color-salvia-500: #6A5ACD;
              --color-salvia-600: #5a4ab8;
            }
          CSS
        end
        
        say "   - app/assets/stylesheets/ : Tailwind CSS entry point created (v4)"
        say ""
        say "⚠️  Run 'bundle install' to install Tailwind CSS.", :yellow
        say "⚠️  To build CSS, run:", :yellow
        say "   bundle exec tailwindcss -i app/assets/stylesheets/application.tailwind.css -o public/assets/stylesheets/tailwind.css --watch"
      end

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
