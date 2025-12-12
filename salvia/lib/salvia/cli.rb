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

      # 1. Backend Framework
      backend = if File.exist?("bin/rails") || File.exist?("config/application.rb")
                  "rails"
                else
                  "other"
                end

      # 2. Tailwind CSS
      install_tailwind = yes?("1. Do you want to install Tailwind CSS (via tailwindcss-ruby)? (y/N)", :yellow)

      say ""
      say "🚀 Installing Salvia (Preact + Signals) for #{backend}...", :green
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
      copy_file "assets/components/Island.tsx", "salvia/app/components/Island.tsx"
      copy_file "assets/islands/Counter.tsx", "salvia/app/islands/Counter.tsx"
      copy_file "assets/pages/Home.tsx", "salvia/app/pages/Home.tsx"
      
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

      # Cache Deno dependencies
      say ""
      say "📦 Caching Deno dependencies...", :green
      sidecar_script = File.expand_path("../../../assets/scripts/sidecar.ts", __FILE__)
      
      # Use user's deno.json if available, otherwise fallback to internal
      user_config = File.expand_path("salvia/deno.json")
      config_path = if File.exist?(user_config)
                      user_config
                    else
                      File.expand_path("../../../assets/scripts/deno.json", __FILE__)
                    end

      if system("deno cache --config #{config_path} #{sidecar_script}")
        say "   - Dependencies cached successfully"
      else
        say "   - Warning: Failed to cache dependencies (non-fatal)", :yellow
      end

      say ""
      say "✅ Salvia SSR installed!", :green
      say "   - salvia/app/islands/    : Put your interactive Island components here"
      say "   - salvia/app/pages/      : Put your static Server Components here (JS-free)"
      say "   - salvia/app/components/ : Put your shared/static components here"
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
      
      # Use internal build script
      build_script = File.expand_path("../../../assets/scripts/build.ts", __FILE__)
      
      # Use user's deno.json if available, otherwise fallback to internal
      user_config = File.expand_path("salvia/deno.json")
      config_path = if File.exist?(user_config)
                      user_config
                    else
                      File.expand_path("../../../assets/scripts/deno.json", __FILE__)
                    end
      
      cmd = "deno run --allow-all --config #{config_path} #{build_script}"
      cmd += " --verbose" if options[:verbose]
      
      success = system(cmd)
      
      if success
        say "✅ SSR build completed!", :green
      else
        say "❌ SSR build failed", :red
        exit 1
      end

      # Build Tailwind CSS if available
      if File.exist?("bin/rails")
        say "🎨 Building Tailwind CSS...", :green
        # Check if tailwindcss:build task exists
        if system("bin/rails -T | grep tailwindcss:build > /dev/null 2>&1")
          if system("bin/rails tailwindcss:build")
            say "✅ Tailwind CSS build completed!", :green
          else
            say "❌ Tailwind CSS build failed", :red
            # Don't exit here, as SSR build succeeded
          end
        end
      end
    end

    desc "watch", "Watch and rebuild Island components"
    method_option :verbose, aliases: "-v", type: :boolean, default: false, desc: "Verbose output"
    def watch
      check_deno_installed!
      
      say "👀 Watching Island components...", :green
      
      # Use internal build script
      build_script = File.expand_path("../../../assets/scripts/build.ts", __FILE__)
      
      # Use user's deno.json if available, otherwise fallback to internal
      user_config = File.expand_path("salvia/deno.json")
      config_path = if File.exist?(user_config)
                      user_config
                    else
                      File.expand_path("../../../assets/scripts/deno.json", __FILE__)
                    end
      
      cmd = "deno run --allow-all --config #{config_path} #{build_script} --watch"
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
