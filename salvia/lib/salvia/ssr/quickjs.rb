# frozen_string_literal: true

require "json"

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
        
        @vm = ::Quickjs::VM.new
        
        load_console_shim!
        
        if @development
          load_vendor_bundle!
        else
          load_ssr_bundle!
        end
        
        mark_initialized!
      end
      
      def shutdown!
        @vm = nil
        @js_logs = []
        @initialized = false
        Salvia::Compiler.shutdown if @development
      end

      def render(component_name, props = {})
        log_info("[Salvia] Rendering #{component_name}") if @development
        raise Error, "Engine not initialized" unless initialized?
        
        if @development
          render_jit(component_name, props)
        else
          render_production(component_name, props)
        end
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
          js_code = Salvia::Compiler.bundle(
            path, 
            externals: ["preact", "preact/hooks", "preact-render-to-string"],
            format: "iife",
            global_name: "SalviaComponent"
          )
          
          # Async Type Check
          Thread.new do
            begin
              result = Salvia::Compiler.check(path)
              unless result["success"]
                log_warn("Type Check Failed for #{component_name}:\n#{result["message"]}")
              end
            rescue => e
              log_debug("Type Check Error: #{e.message}")
            end
          end

          eval_js(js_code)
          
          # Render
          render_script = <<~JS
            (function() {
              try {
                const Component = SalviaComponent.default;
                if (!Component) throw new Error("Component default export not found in " + "#{escape_js(component_name)}");
                const vnode = h(Component, #{props.to_json});
                const html = renderToString(vnode);
                return JSON.stringify(html);
              } catch (e) {
                return JSON.stringify({ __ssr_error__: true, message: e.message, stack: e.stack || '' });
              }
            })()
          JS
          
          result = eval_js(render_script)
          
          begin
            parsed = JSON.parse(result)
            if parsed.is_a?(Hash) && parsed["__ssr_error__"]
              @last_build_error = parsed['message']
              return ssr_error_overlay(component_name, parsed)
            end
            return parsed
          rescue JSON::ParserError
            if result.nil?
              log_error("Render result is nil")
              return nil
            end
            return result
          end
        rescue => e
          log_error("Render JIT Error: #{e.message}")
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
              const html = globalThis.SalviaSSR.render('#{escape_js(component_name)}', #{props.to_json});
              return JSON.stringify(html);
            } catch (e) {
              return JSON.stringify({ __ssr_error__: true, message: e.message, stack: e.stack || '' });
            }
          })()
        JS

        result = eval_js(js_code)
        
        begin
          parsed = JSON.parse(result)
          if parsed.is_a?(Hash) && parsed["__ssr_error__"]
            return ssr_error_overlay(component_name, parsed)
          end
          return parsed
        rescue JSON::ParserError
          return result
        end
      end

      def eval_js(code)
        result = @vm.eval_code(code)
        process_console_output
        result
      rescue => e
        process_console_output
        raise e
      end
      
      def load_console_shim!
        shim = generate_console_shim
        @vm.eval_code(shim)
        @vm.eval_code(Salvia::SSR::DomMock.generate_shim)
      rescue => e
        log_error("Failed to load console shim: #{e.message}")
      end
      
      def load_vendor_bundle!
        # Use internal vendor_setup.ts for Zero Config
        vendor_path = File.expand_path("../../../assets/scripts/vendor_setup.ts", __dir__)
        
        if File.exist?(vendor_path)
          code = Salvia::Compiler.bundle(vendor_path, format: "iife")
          eval_js(code)
          log_info("Loaded Vendor bundle (Internal)")
        else
          log_error("Internal vendor_setup.ts not found at #{vendor_path}")
        end
      rescue => e
        log_error("Failed to load vendor bundle: #{e.message}")
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
        Salvia::Core::PathResolver.resolve(name)
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
