# frozen_string_literal: true

require "json"
require "salvia/sidecar"

module Salvia
  module SSR
    class QuickJS < BaseAdapter
      attr_reader :js_logs
      attr_accessor :last_build_error

      def setup!
        require_quickjs!
        
        @js_logs = []
        @last_build_error = nil
        @development = options.fetch(:development, true)
        
        # 1. VMインスタンスを作成して保持
        @vm = ::Quickjs::VM.new
        
        # 2. 初期化スクリプトをロード
        load_console_shim!
        
        if @development
          # JIT Mode
          Salvia::Sidecar.instance.start
          load_vendor_bundle!
        else
          # Production Mode
          load_ssr_bundle!
        end
        
        mark_initialized!
      end

      def render(component_name, props = {})
        raise Error, "Engine not initialized" unless initialized?
        
        if @last_build_error && @development
          return build_error_html(@last_build_error)
        end

        if @development
          render_jit(component_name, props)
        else
          render_production(component_name, props)
        end
      end

      def reload_bundle!
        # リロード時はVMを作り直してリセットする
        @vm = ::Quickjs::VM.new
        load_console_shim!
        
        if @development
          load_vendor_bundle!
        else
          load_ssr_bundle!
        end
      end
      
      def shutdown!
        @vm = nil # ガベージコレクションに任せる
        @js_logs = []
        @initialized = false
        Salvia::Sidecar.instance.stop if @development
      end

      private

      def vm
        @vm
      end

      def render_jit(component_name, props)
        begin
          path = resolve_path(component_name)
          unless path
            raise Error, "Component not found: #{component_name}"
          end
          
          # Bundle component
          js_code = Salvia::Sidecar.instance.bundle(path, externals: ["preact", "preact/hooks", "preact-render-to-string"])
          
          # Async Type Check
          Thread.new do
            begin
              result = Salvia::Sidecar.instance.check(path)
              unless result["success"]
                log_warn("Type Check Failed for #{component_name}:\n#{result["message"]}")
              end
            rescue => e
              log_debug("Type Check Error: #{e.message}")
            end
          end

          @vm.eval_code(js_code)
          
          # Render
          render_script = <<~JS
            (function() {
              try {
                const Component = SalviaComponent.default;
                if (!Component) throw new Error("Component default export not found in " + "#{escape_js(component_name)}");
                const vnode = h(Component, #{props.to_json});
                return renderToString(vnode);
              } catch (e) {
                return JSON.stringify({ __ssr_error__: true, message: e.message, stack: e.stack || '' });
              }
            })()
          JS
          
          result = eval_js(render_script)
          
          if result&.start_with?('{"__ssr_error__":true')
            error_data = JSON.parse(result)
            @last_build_error = error_data['message']
            return ssr_error_overlay(component_name, error_data)
          end
          
          return result
        rescue => e
          @last_build_error = e.message
          return build_error_html(e.message)
        end
      end

      def render_production(component_name, props)
        js_code = <<~JS
          (function() {
            try {
              if (typeof globalThis.SalviaSSR === 'undefined') {
                throw new Error('SalviaSSR runtime not loaded.');
              }
              return globalThis.SalviaSSR.render('#{escape_js(component_name)}', #{props.to_json});
            } catch (e) {
              return JSON.stringify({ __ssr_error__: true, message: e.message, stack: e.stack || '' });
            }
          })()
        JS

        result = eval_js(js_code)
        
        if result&.start_with?('{"__ssr_error__":true')
          error_data = JSON.parse(result)
          return ssr_error_overlay(component_name, error_data)
        end
        
        result
      end

      def eval_js(code)
        result = @vm.eval_code(code)
        process_console_output
        result
      end
      
      def load_console_shim!
        shim = generate_console_shim
        @vm.eval_code(shim)
      end
      
      def load_vendor_bundle!
        vendor_path = File.join(Salvia.root, "salvia/vendor_setup.ts")
        if File.exist?(vendor_path)
          code = Salvia::Sidecar.instance.bundle(vendor_path)
          @vm.eval_code(code)
          log_info("Loaded Vendor bundle (JIT)")
        else
          log_warn("vendor_setup.ts not found. JIT mode might fail.")
        end
      end
      
      def load_ssr_bundle!
        bundle_path = options[:bundle_path] || default_bundle_path
        
        unless File.exist?(bundle_path)
          raise Error, "SSR bundle not found: #{bundle_path}"
        end
        
        bundle_content = File.read(bundle_path)
        @vm.eval_code(bundle_content)
        log_info("Loaded SSR bundle: #{bundle_path}")
      end
      
      def resolve_path(name)
        roots = [
          "salvia/app/pages",
          "salvia/app/islands",
          "salvia/app/components"
        ]
        
        roots.each do |root|
          path = File.join(Salvia.root, root, "#{name}.tsx")
          return path if File.exist?(path)
          
          path = File.join(Salvia.root, root, "#{name}.jsx")
          return path if File.exist?(path)
          
          path = File.join(Salvia.root, root, "#{name}.js")
          return path if File.exist?(path)
        end
        
        if name.include?("/")
           path = File.join(Salvia.root, "salvia/app", "#{name}.tsx")
           return path if File.exist?(path)
        end
        
        nil
      end
      
      def process_console_output
        logs_json = @vm.eval_code("globalThis.__salvia_flush_logs__()")
        return if logs_json.nil? || logs_json.empty?
        
        begin
          logs = JSON.parse(logs_json)
          logs.each do |log|
            @js_logs << log
            case log["level"]
            when "error"
              log_error("JS: #{log['message']}")
            when "warn"
              log_warn("JS: #{log['message']}")
            else
              log_debug("JS: #{log['message']}")
            end
          end
        rescue JSON::ParserError
        end
      end

      def generate_console_shim
        <<~JS
          (function() {
            var __salvia_logs__ = [];
            globalThis.console = {
              log: function() { __salvia_logs__.push({ level: 'log', message: Array.from(arguments).join(' ') }); },
              error: function() { __salvia_logs__.push({ level: 'error', message: Array.from(arguments).join(' ') }); },
              warn: function() { __salvia_logs__.push({ level: 'warn', message: Array.from(arguments).join(' ') }); },
              info: function() { __salvia_logs__.push({ level: 'info', message: Array.from(arguments).join(' ') }); },
              debug: function() { __salvia_logs__.push({ level: 'debug', message: Array.from(arguments).join(' ') }); }
            };
            globalThis.__salvia_flush_logs__ = function() {
              var logs = __salvia_logs__;
              __salvia_logs__ = [];
              return JSON.stringify(logs);
            };
          })();
        JS
      end

      def ssr_error_overlay(component_name, error_data)
        <<~HTML
          <div style="background:#fee;border:2px solid #c00;padding:20px;margin:10px 0;">
            <h3>SSR Error in #{escape_html(component_name)}</h3>
            <pre>#{escape_html(error_data['message'])}</pre>
            <details><summary>Stack Trace</summary><pre>#{escape_html(error_data['stack'])}</pre></details>
          </div>
        HTML
      end
      
      def build_error_html(error_message)
        <<~HTML
          <div style="background:#1a1a2e;color:#ff6b6b;padding:20px;position:fixed;inset:0;z-index:9999;">
            <h2>SSR Build Failed</h2>
            <pre>#{escape_html(error_message)}</pre>
          </div>
        HTML
      end

      def default_bundle_path
        File.join(Dir.pwd, "salvia", "server", "ssr_bundle.js")
      end

      def require_quickjs!
        require "quickjs"
      rescue LoadError
        raise Error, "quickjs gem is not installed."
      end

      def escape_js(str)
        str.to_s.gsub(/['\\]/) { |c| "\\#{c}" }
      end
      
      def escape_html(str)
        str.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
      end
      
      def log_info(msg); defined?(Salvia.logger) ? Salvia.logger.info(msg) : puts("[SSR] #{msg}"); end
      def log_warn(msg); defined?(Salvia.logger) ? Salvia.logger.warn(msg) : puts("[SSR WARNING] #{msg}"); end
      def log_error(msg); defined?(Salvia.logger) ? Salvia.logger.error(msg) : puts("[SSR ERROR] #{msg}"); end
      def log_debug(msg); defined?(Salvia.logger) ? Salvia.logger.debug(msg) : puts("[SSR DEBUG] #{msg}") if ENV["DEBUG"]; end
    end
  end
end
