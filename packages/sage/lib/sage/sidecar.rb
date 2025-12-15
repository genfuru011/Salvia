require "async"
require "async/http/endpoint"
require "async/http/client"
require "io/endpoint/unix_endpoint"
require "json"
require "fileutils"
require "active_support/core_ext/object/json"

module Sage
  class Sidecar
    SOCKET_PATH = "tmp/sockets/sage_deno.sock"
    PID_FILE = "tmp/pids/sage_deno.pid"

    class << self
      def socket_path
        SOCKET_PATH
      end

      def ensure_running!
        return if running?

        start_process
        wait_for_socket
      end

      def restart!
        stop_process
        start_process
        wait_for_socket
      end

      def rpc(command, params = {})
        ensure_running!

        # We assume this is called within an Async reactor (Falcon)
        endpoint = Async::HTTP::Endpoint.parse("http://sage-sidecar/rpc/#{command}")
        endpoint.endpoint = IO::Endpoint.unix(SOCKET_PATH)
        
        begin
          client = Async::HTTP::Client.new(endpoint)
          # Ensure params are converted to primitives using as_json (ActiveSupport)
          # This handles ActiveRecord objects and other custom types
          payload = JSON.generate(params.as_json)
          response = client.post(endpoint.path, [], payload)
          response.read # Return body string
        ensure
          client&.close
        end
      end

      private

      def running?
        return false unless File.exist?(PID_FILE)
        
        pid = File.read(PID_FILE).to_i
        Process.kill(0, pid)
        true
      rescue Errno::ESRCH, Errno::ENOENT
        false
      end

      def stop_process
        return unless File.exist?(PID_FILE)
        
        pid = File.read(PID_FILE).to_i
        Process.kill("TERM", pid)
        Process.wait(pid)
      rescue Errno::ESRCH, Errno::ENOENT, Errno::ECHILD
        # Already dead
      ensure
        File.unlink(PID_FILE) if File.exist?(PID_FILE)
        File.unlink(SOCKET_PATH) if File.exist?(SOCKET_PATH)
      end

      def start_process
        puts "🦕 Starting Deno Sidecar..."
        FileUtils.mkdir_p("tmp/sockets")
        FileUtils.mkdir_p("tmp/pids")
        
        File.unlink(SOCKET_PATH) if File.exist?(SOCKET_PATH)

        # Resolve path to server.ts in the gem
        server_path = File.expand_path("../../assets/adapter/server.ts", __dir__)

        pid = spawn(
          { "SOCKET_PATH" => SOCKET_PATH },
          "deno run -A --unstable-net #{server_path}"
        )
        
        File.write(PID_FILE, pid)
        Process.detach(pid)
      end

      def wait_for_socket
        10.times do
          break if File.exist?(SOCKET_PATH)
          sleep 0.1
        end
      end
    end
  end
end
