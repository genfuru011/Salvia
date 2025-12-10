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
      say "🌿 Salvia Installer", :bold
      say "===================", :bold
      say ""

      # 1. Select Frontend Framework
      frontend = ask("1. Which frontend framework do you want to use?", :yellow, limited_to: ["preact", "react", "vue", "solid", "hono"], default: "preact")
      
      if frontend != "preact"
        say "⚠️  Currently only Preact is fully supported in v0.1.0. Falling back to Preact.", :red
        frontend = "preact"
      end

      # 2. Select Backend Framework
      backend = ask("2. Which backend framework are you using?", :yellow, limited_to: ["sinatra", "rails", "hanami", "other"], default: "sinatra")

      # 3. Tailwind CSS
      install_tailwind = yes?("3. Do you want to install Tailwind CSS (via tailwindcss-ruby)? (y/N)", :yellow)

      say ""
      say "🚀 Installing Salvia with #{frontend} for #{backend}...", :green
      say ""

      # Create directories
      empty_directory "salvia/app/islands"
      empty_directory "salvia/app/pages"
      empty_directory "salvia/app/components"
      empty_directory "public/assets/javascripts"
      empty_directory "public/assets/islands"
      empty_directory "salvia"

      # Copy files
      # Note: source_root is 'salvia/', so paths are relative to that
      copy_file "assets/scripts/deno.json", "salvia/deno.json"
      copy_file "assets/scripts/build.ts", "salvia/build.ts"
      copy_file "assets/javascripts/islands.js", "public/assets/javascripts/islands.js"
      
      create_file "salvia/.gitignore", "/server/\n"

      # Backend Setup
      case backend
      when "rails"
        create_file "config/initializers/salvia.rb" do
          <<~RUBY
            Salvia.configure do |config|
              config.islands_dir = Rails.root.join("salvia/app/islands")
              config.build_dir = Rails.root.join("public/assets")
              config.ssr_bundle_path = Rails.root.join("salvia/server/ssr_bundle.js")
            end
            
            # Initialize SSR Engine
            Salvia::SSR.configure(
              bundle_path: Salvia.config.ssr_bundle_path,
              development: Rails.env.development?
            )
          RUBY
        end
        say "   - Created config/initializers/salvia.rb"
      end

      # Tailwind CSS Setup
      if install_tailwind
        # Add tailwindcss-ruby to Gemfile if present
        if File.exist?("Gemfile")
          unless File.read("Gemfile").include?("tailwindcss-ruby")
            append_to_file "Gemfile", "\ngem 'tailwindcss-ruby'\n"
            say "   - Added 'tailwindcss-ruby' to Gemfile"
          end
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
      end

      chmod "salvia/build.ts", 0755

      say ""
      say "✅ Salvia SSR installed!", :green
      say "   - salvia/app/islands/    : Put your interactive Island components here"
      say "   - salvia/app/pages/      : Put your static Server Components here (JS-free)"
      say "   - salvia/app/components/ : Put your shared/static components here"
      say "   - salvia/build.ts        : Build script"
      say "   - salvia/deno.json       : Deno configuration"
      say ""
      say "Next steps:", :yellow
      say "  1. Install Deno: https://deno.land"
      if install_tailwind
        say "  2. Run 'bundle install' to install Tailwind"
        say "  3. Run build: salvia build"
        say "  4. Watch assets: bundle exec foreman start -f Procfile.dev (recommended)"
      else
        say "  2. Run build: salvia build"
      end
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
