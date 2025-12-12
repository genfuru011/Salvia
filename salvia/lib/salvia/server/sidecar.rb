require 'net/http'
require 'uri'
require 'json'
require 'timeout'

module Salvia
  module Server
    class Sidecar
    SCRIPT_PATH = File.join(__dir__, "sidecar.ts")

    def self.instance
      @instance ||= new
    end

    def initialize
      @pid = nil
      @port = nil
      @mutex = Mutex.new
      at_exit { stop }
    end

    def start
      @mutex.synchronize do
        return if running?

        cmd = ["deno", "run", "--allow-net", "--allow-read", "--allow-env", SCRIPT_PATH]
        
        puts "🚀 Starting Salvia Sidecar..."
        # Spawn process and capture stdout to find the port
        # We use IO.popen to read the output stream
        @io = IO.popen(cmd)
        @pid = @io.pid
        
        # Wait for JSON handshake
        wait_for_handshake
        
        # Detach so it runs in background, but we keep the IO open to read logs if needed
        # Actually, for IO.popen, we shouldn't detach if we want to read from it.
        # But we need to read in a non-blocking way or in a separate thread after finding the port.
        
        Thread.new do
          begin
            while line = @io.gets
              # Forward Deno logs to stdout/logger
              puts "[Deno] #{line}"
            end
          rescue IOError
            # Stream closed
          end
        end
      end
    end

    def stop
      return unless @pid
      Process.kill("TERM", @pid)
      @pid = nil
      @port = nil
      @io.close if @io && !@io.closed?
    end

    def running?
      return false unless @pid
      Process.getpgid(@pid)
      true
    rescue Errno::ESRCH
      false
    end

    def bundle(entry_point, externals: [], format: "esm", global_name: nil, config_path: nil)
      start unless running?
      
      resolved_config_path = File.expand_path(config_path || Salvia.config.deno_config_path, Salvia.root)
      puts "[Salvia] Bundle config path: #{resolved_config_path}"

      response = request("bundle", { 
        entryPoint: entry_point, 
        externals: externals,
        format: format,
        globalName: global_name,
        configPath: resolved_config_path
      })
      if response["error"]
        raise "Sidecar Bundle Error: #{response["error"]}"
      end
      response["code"]
    end

    def check(entry_point, config_path: nil)
      start unless running?
      resolved_config_path = File.expand_path(config_path || Salvia.config.deno_config_path, Salvia.root)
      request("check", { entryPoint: entry_point, configPath: resolved_config_path })
    end

    def fmt(entry_point, config_path: nil)
      start unless running?
      resolved_config_path = File.expand_path(config_path || Salvia.config.deno_config_path, Salvia.root)
      request("fmt", { entryPoint: entry_point, configPath: resolved_config_path })
    end

    private

    def wait_for_handshake
      Timeout.timeout(30) do
        while line = @io.gets
          # Try to parse JSON handshake
          if line.strip.start_with?("{") && line.include?("port")
            begin
              data = JSON.parse(line)
              if data["port"]
                @port = data["port"]
                puts "✅ Salvia Sidecar connected on port #{@port}"
                return
              end
            rescue JSON::ParserError
              # Not JSON, just log
              puts "[Deno Init] #{line}"
            end
          else
            puts "[Deno Init] #{line}"
          end
        end
        # If we exit the loop, it means EOF (process died)
        raise "Deno Sidecar crashed unexpectedly. Check logs."
      end
    rescue Timeout::Error
      stop
      raise "Sidecar failed to start (Timeout waiting for port)"
    end

    def request(command, params = {})
      uri = URI("http://localhost:#{@port}/")
      http = Net::HTTP.new(uri.host, uri.port)
      
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request.body = { command: command, params: params }.to_json
      
      response = http.request(request)
      
      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      else
        raise "Sidecar Request Failed: #{response.code} #{response.message}"
      end
    rescue => e
      raise "Sidecar Request Error: #{e.message}"
    end
    end
  end
end
