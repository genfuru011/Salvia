require 'socket'
require 'json'

module Salvia
  class Sidecar
    SOCKET_PATH = "/tmp/salvia.sock"
    SCRIPT_PATH = "salvia/sidecar.ts"

    def self.instance
      @instance ||= new
    end

    def initialize
      @pid = nil
    end

    def start
      return if running?

      # Remove socket if it exists (cleanup from crash)
      File.unlink(SOCKET_PATH) if File.exist?(SOCKET_PATH)

      cmd = ["deno", "run", "--allow-all", SCRIPT_PATH, SOCKET_PATH]
      
      puts "🚀 Starting Salvia Sidecar..."
      # Spawn process
      @pid = spawn(*cmd, out: $stdout, err: $stderr)
      Process.detach(@pid)

      wait_for_socket
    end

    def stop
      return unless @pid
      Process.kill("TERM", @pid)
      @pid = nil
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

    private

    def wait_for_socket
      20.times do
        break if File.exist?(SOCKET_PATH)
        sleep 0.1
      end
      raise "Sidecar failed to start (Socket not found at #{SOCKET_PATH})" unless File.exist?(SOCKET_PATH)
    end

    def request(command, params = {})
      socket = UNIXSocket.new(SOCKET_PATH)
      
      payload = { command: command, params: params }.to_json
      
      # HTTP/1.1 Request over Unix Socket
      request_str = "POST / HTTP/1.1\r\n" \
                    "Host: localhost\r\n" \
                    "Content-Type: application/json\r\n" \
                    "Content-Length: #{payload.bytesize}\r\n" \
                    "\r\n" \
                    "#{payload}"
      
      socket.write(request_str)
      
      # Read Response
      response_header = ""
      while line = socket.gets
        response_header += line
        break if line == "\r\n"
      end
      
      # Parse Content-Length
      if match = response_header.match(/Content-Length: (\d+)/i)
        content_length = match[1].to_i
        body = socket.read(content_length)
        socket.close
        JSON.parse(body)
      else
        socket.close
        raise "Invalid response from Sidecar"
      end
    rescue => e
      raise "Sidecar Request Error: #{e.message}"
    end
  end
end
