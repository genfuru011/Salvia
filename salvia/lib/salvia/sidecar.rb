require 'net/http'
require 'uri'
require 'json'
require 'timeout'

module Salvia
  class Sidecar
    SCRIPT_PATH = File.join(__dir__, "sidecar.ts")

    def self.instance
      @instance ||= new
    end

    def initialize
      @pid = nil
      @port = nil
    end

    def start
      return if running?

      cmd = ["deno", "run", "--allow-all", SCRIPT_PATH]
      
      puts "🚀 Starting Salvia Sidecar..."
      # Spawn process and capture stdout to find the port
      # We use IO.popen to read the output stream
      @io = IO.popen(cmd)
      @pid = @io.pid
      
      # Wait for "Listening on http://localhost:PORT/"
      wait_for_port
      
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

    def bundle(entry_point, externals: [])
      start unless running?
      
      response = request("bundle", { entryPoint: entry_point, externals: externals })
      if response["error"]
        raise "Sidecar Bundle Error: #{response["error"]}"
      end
      response["code"]
    end

    def check(entry_point)
      start unless running?
      request("check", { entryPoint: entry_point })
    end

    def fmt(entry_point)
      start unless running?
      request("fmt", { entryPoint: entry_point })
    end

    private

    def wait_for_port
      Timeout.timeout(10) do
        while line = @io.gets
          puts "[Deno Init] #{line}"
          if match = line.match(/Listening on http:\/\/localhost:(\d+)\//)
            @port = match[1].to_i
            puts "✅ Salvia Sidecar connected on port #{@port}"
            return
          end
        end
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
