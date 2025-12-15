require "thor"
require "fileutils"
require "sage/version"

module Sage
  class CLI < Thor
    include Thor::Actions

    def self.source_root
      File.expand_path("../../templates", __dir__)
    end

    desc "new APP_NAME", "Create a new Sage application"
    def new(app_name)
      @app_name = app_name
      
      say "🌿 Creating new Sage application: #{app_name}", :green

      directory "app", "#{app_name}"
      
      # Run bundle install
      inside app_name do
        run "bundle install"
      end
      
      say ""
      say "✅ #{app_name} created successfully!", :green
      say "To get started:"
      say "  cd #{app_name}"
      say "  bundle exec sage dev        # Start dev server"
    end
    
    desc "server", "Start the Sage server"
    method_option :port, aliases: "-p", type: :numeric, default: 3000, desc: "Port to listen on"
    def server
      require "sage"
      
      # Load application
      app_file = File.join(Dir.pwd, "config/application.rb")
      unless File.exist?(app_file)
        say "❌ config/application.rb not found. Are you in a Sage project?", :red
        exit 1
      end
      
      require app_file
      
      port = options[:port].to_i
      Sage::Server.new(App.new).start(port: port)
    end

    desc "dev", "Start the Sage server in development mode with live reloading"
    method_option :port, aliases: "-p", type: :numeric, default: 3000, desc: "Port to listen on"
    def dev
      require "listen"
      
      port = options[:port]
      
      say "🌿 Starting Sage development server...", :green
      
      # Function to start the server
      start_server = proc do
        env = { "RACK_ENV" => "development", "RUBY_YJIT_ENABLE" => "1" }
        pid = spawn(env, "bundle exec sage server -p #{port}")
        Process.detach(pid)
        pid
      end
      
      server_pid = start_server.call
      
      # Directories to watch
      directories = ["app", "config", "lib"].select { |d| File.directory?(d) }
      
      listener = Listen.to(*directories, only: /\.rb$/) do |modified, added, removed|
        say "🔄 File changed, restarting server...", :yellow
        begin
          Process.kill("TERM", server_pid)
          Process.wait(server_pid)
        rescue Errno::ESRCH, Errno::ECHILD
          # Process already dead
        end
        server_pid = start_server.call
      end
      
      listener.start
      
      # Handle Ctrl+C
      trap("INT") do
        listener.stop
        begin
          Process.kill("TERM", server_pid) if server_pid
        rescue Errno::ESRCH
        end
        exit
      end
      
      sleep
    end

    private

    # Removed legacy generate_client method
  end
end
