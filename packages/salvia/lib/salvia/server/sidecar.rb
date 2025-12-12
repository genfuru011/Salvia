require 'net/http'
require 'uri'
require 'json'
require 'timeout'
require 'tmpdir'
require 'securerandom'
require 'socket'

module Salvia
  module Server
    class Sidecar
    SCRIPT_PATH = File.expand_path("../../../assets/scripts/sidecar.ts", __dir__)

    def self.instance
      @instance ||= new
    end

    def initialize
      @pid = nil
      @port = nil
      @socket_path = nil
      @socket = nil
      @mutex = Mutex.new
      at_exit { stop }
    end

    def start
      @mutex.synchronize do
        return if running?

        # Create a unique socket path
        @socket_path = File.join(Dir.tmpdir, "salvia-sidecar-#{SecureRandom.hex(8)}.sock")
        
        # Pass socket path via env
        env = { "SALVIA_SOCKET_PATH" => @socket_path }
        cmd = ["deno", "run", "--allow-net", "--allow-read", "--allow-env", "--allow-run", "--allow-import", "--allow-write", SCRIPT_PATH]
        
        puts "🚀 Starting Salvia Sidecar..."
        # Spawn process and capture stdout to find the port/socket
        @io = IO.popen(env, cmd, err: [:child, :out])
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
      
      begin
        Process.kill("TERM", @pid)
        
        # Wait up to 5 seconds for graceful shutdown
        50.times do
          pid = Process.waitpid(@pid, Process::WNOHANG)
          if pid
            @pid = nil
            break
          end
          sleep 0.1
        end
        
        # Force kill if still running
        if @pid
          Process.kill("KILL", @pid)
          Process.waitpid(@pid, Process::WNOHANG) rescue nil
        end
      rescue Errno::ESRCH, Errno::ECHILD
        # Process already dead
      ensure
        @pid = nil
        @port = nil
        if @socket_path && File.exist?(@socket_path)
          File.unlink(@socket_path) rescue nil
        end
        @socket_path = nil
        @socket&.close rescue nil
        @socket = nil
        @io.close if @io && !@io.closed?
      end
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
          if line.strip.start_with?("{") && (line.include?("port") || line.include?("socket"))
            begin
              data = JSON.parse(line)
              if data["socket"]
                @socket_path = data["socket"]
                puts "✅ Salvia Sidecar connected on unix:#{@socket_path}"
                return
              elsif data["port"]
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
      raise "Sidecar failed to start (Timeout waiting for port/socket)"
    end

    def request(command, params = {})
      if @socket_path
        @mutex.synchronize do
          begin
            perform_request(command, params)
          rescue Errno::EPIPE, EOFError, IOError
            # Retry once on connection failure
            @socket&.close rescue nil
            @socket = nil
            perform_request(command, params)
          end
        end
      else
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
      end
    rescue => e
      raise "Sidecar Request Error: #{e.message}"
    end

    private

    def perform_request(command, params)
      connect_socket! unless @socket && !@socket.closed?
      
      body = { command: command, params: params }.to_json
      
      @socket.write "POST / HTTP/1.1\r\n"
      @socket.write "Host: localhost\r\n"
      @socket.write "Content-Type: application/json\r\n"
      @socket.write "Content-Length: #{body.bytesize}\r\n"
      @socket.write "Connection: keep-alive\r\n"
      @socket.write "\r\n"
      @socket.write body
      
      # Read status line
      status_line = @socket.gets
      unless status_line&.include?("200 OK")
        raise "Sidecar Request Failed: #{status_line}"
      end
      
      # Read headers
      content_length = nil
      is_chunked = false
      
      while line = @socket.gets
        line = line.strip
        break if line.empty?
        
        if line.match?(/^Content-Length:/i)
          content_length = line.split(":", 2)[1].strip.to_i
        elsif line.match?(/^Transfer-Encoding:\s*chunked/i)
          is_chunked = true
        end
      end
      
      response_body = ""
      
      if is_chunked
        while true
          line = @socket.gets
          break unless line
          size = line.strip.to_i(16)
          break if size == 0
          
          chunk = @socket.read(size)
          response_body << chunk
          @socket.gets # Consume CRLF
        end
      elsif content_length
        response_body = @socket.read(content_length)
      else
        # Without content-length or chunked, we can't know when it ends in keep-alive
        # But Deno server should send one of them.
        # Fallback to read until EOF (which breaks keep-alive)
        response_body = @socket.read
        @socket.close
        @socket = nil
      end
      
      JSON.parse(response_body)
    end

    def connect_socket!
      @socket = UNIXSocket.new(@socket_path)
    end
    end
  end
end
