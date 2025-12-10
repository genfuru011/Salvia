# frozen_string_literal: true

require "json"

module Salvia
  module SSR
    # QuickJS SSR Engine
    #
    # Deno でビルドした ssr_bundle.js を読み込み、
    # 同一プロセス内で高速に SSR を実行します。
    #
    # Features:
    # - console.log を Ruby Logger に転送
    # - SSR エラー時のオーバーレイ HTML 生成
    # - 開発/本番モードの切り替え
    #
    # @example
    #   Salvia::SSR.configure(bundle_path: "vendor/server/ssr_bundle.js")
    #   html = Salvia::SSR.render("Counter", { count: 5 })
    #
    class QuickJS < BaseAdapter
        # JS から収集したログを保持
        attr_reader :js_logs
        
        # 最後のビルドエラー
        attr_accessor :last_build_error

        def setup!
          require_quickjs!
          
          @js_logs = []
          @last_build_error = nil
          @development = options.fetch(:development, true)
          
          # VMインスタンスを作成して保持
          @vm = ::Quickjs::VM.new
          
          # console.log 転送用の shim をロード
          load_console_shim!
          
          # Deno ビルド済みバンドルをロード
          load_ssr_bundle!
          
          mark_initialized!
        end

        # コンポーネントを HTML にレンダリング
        #
        # @param component_name [String] コンポーネント名
        # @param props [Hash] プロパティ
        # @return [String] レンダリングされた HTML
        def render(component_name, props = {})
          raise Error, "Engine not initialized" unless initialized?
          
          # ビルドエラーがある場合は HUD を表示
          if @last_build_error && @development
            return build_error_html(@last_build_error)
          end

          js_code = <<~JS
            (function() {
              try {
                if (typeof globalThis.SalviaSSR === 'undefined') {
                  throw new Error('SalviaSSR runtime not loaded. Run: deno run --allow-all bin/build_ssr.ts');
                }
                return globalThis.SalviaSSR.render('#{escape_js(component_name)}', #{props.to_json});
              } catch (e) {
                return JSON.stringify({ __ssr_error__: true, message: e.message, stack: e.stack || '' });
              }
            })()
          JS

          result = eval_js(js_code)
          
          # エラーチェック
          if result&.start_with?('{"__ssr_error__":true')
            error_data = JSON.parse(result)
            if @development
              return ssr_error_overlay(component_name, error_data)
            else
              # 本番環境では空を返してクライアントサイドレンダリングにフォールバック
              log_error("SSR Error in #{component_name}: #{error_data['message']}")
              return ""
            end
          end
          
          result
        end

        # バンドルをリロード (開発モードでのホットリロード用)
        def reload_bundle!
          @vm = ::Quickjs::VM.new
          load_console_shim!
          load_ssr_bundle!
        end
        
        # JS ログをフラッシュして取得
        def flush_logs
          logs = @js_logs.dup
          @js_logs.clear
          logs
        end

        def shutdown!
          @vm = nil
          @js_logs = []
          @initialized = false
        end

        def engine_name
          "QuickJS (Hybrid SSR Engine)"
        end
        
        def development?
          @development
        end

        private

        def eval_js(code)
          result = @vm.eval_code(code)
          
          # console.log の出力を処理
          process_console_output
          
          result
        end
        
        # console.log/error/warn を Ruby に転送する shim
        def load_console_shim!
          shim = <<~JS
            // Salvia Console Shim - Captures JS logs for Ruby
            (function() {
              var __salvia_logs__ = [];
              
              globalThis.console = {
                log: function() {
                  var msg = Array.prototype.slice.call(arguments).map(function(a) {
                    return typeof a === 'object' ? JSON.stringify(a) : String(a);
                  }).join(' ');
                  __salvia_logs__.push({ level: 'log', message: msg });
                },
                error: function() {
                  var msg = Array.prototype.slice.call(arguments).map(function(a) {
                    return typeof a === 'object' ? JSON.stringify(a) : String(a);
                  }).join(' ');
                  __salvia_logs__.push({ level: 'error', message: msg });
                },
                warn: function() {
                  var msg = Array.prototype.slice.call(arguments).map(function(a) {
                    return typeof a === 'object' ? JSON.stringify(a) : String(a);
                  }).join(' ');
                  __salvia_logs__.push({ level: 'warn', message: msg });
                },
                info: function() {
                  var msg = Array.prototype.slice.call(arguments).map(function(a) {
                    return typeof a === 'object' ? JSON.stringify(a) : String(a);
                  }).join(' ');
                  __salvia_logs__.push({ level: 'info', message: msg });
                },
                debug: function() {
                  var msg = Array.prototype.slice.call(arguments).map(function(a) {
                    return typeof a === 'object' ? JSON.stringify(a) : String(a);
                  }).join(' ');
                  __salvia_logs__.push({ level: 'debug', message: msg });
                }
              };
              
              globalThis.__salvia_flush_logs__ = function() {
                var logs = __salvia_logs__;
                __salvia_logs__ = [];
                return JSON.stringify(logs);
              };
            })();
          JS
          
          @vm.eval_code(shim)
        end
        
        # ビルド済みバンドルをロード
        def load_ssr_bundle!
          bundle_path = options[:bundle_path] || default_bundle_path
          
          unless File.exist?(bundle_path)
            if @development
              # 開発モードではバンドルなしでも起動可能（ビルド待ち）
              log_warn("SSR bundle not found: #{bundle_path}")
              log_warn("Run: deno run --allow-all bin/build_ssr.ts")
              return
            else
              raise Error, <<~MSG
                SSR bundle not found: #{bundle_path}
                
                Build it with:
                  deno run --allow-all bin/build_ssr.ts
                
                Or in production:
                  salvia ssr:build
              MSG
            end
          end
          
          bundle_content = File.read(bundle_path)
          @vm.eval_code(bundle_content)
          
          log_info("Loaded SSR bundle: #{bundle_path} (#{(File.size(bundle_path) / 1024.0).round(1)}KB)")
        end
        
        # console.log の出力を処理
        def process_console_output
          logs_json = @vm.eval_code("globalThis.__salvia_flush_logs__()")
          
          return if logs_json.nil? || logs_json.empty?
          
          begin
            logs = JSON.parse(logs_json)
            logs.each do |log|
              @js_logs << log
              
              # Ruby Logger にも出力
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
            # ignore
          end
        end

        # SSR エラー用のオーバーレイ HTML
        def ssr_error_overlay(component_name, error_data)
          <<~HTML
            <div style="
              background: linear-gradient(135deg, #fee 0%, #fcc 100%);
              border: 2px solid #c00;
              border-radius: 8px;
              padding: 20px;
              margin: 10px 0;
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              box-shadow: 0 4px 12px rgba(200, 0, 0, 0.15);
            ">
              <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 15px;">
                <span style="font-size: 24px;">💥</span>
                <h3 style="margin: 0; color: #900; font-size: 16px;">
                  SSR Error in <code style="background: #fff; padding: 2px 6px; border-radius: 4px;">#{escape_html(component_name)}</code>
                </h3>
              </div>
              <pre style="
                background: #1a1a2e;
                color: #ff6b6b;
                padding: 15px;
                border-radius: 6px;
                overflow-x: auto;
                font-size: 13px;
                line-height: 1.5;
                margin: 0;
              ">#{escape_html(error_data['message'])}</pre>
              #{stack_trace_html(error_data['stack'])}
              <p style="margin: 15px 0 0 0; color: #666; font-size: 12px;">
                💡 This error overlay is only shown in development mode.
              </p>
            </div>
          HTML
        end
        
        def stack_trace_html(stack)
          return "" if stack.nil? || stack.empty?
          
          <<~HTML
            <details style="margin-top: 10px;">
              <summary style="cursor: pointer; color: #666; font-size: 13px;">Stack Trace</summary>
              <pre style="
                background: #2a2a3e;
                color: #aaa;
                padding: 10px;
                border-radius: 4px;
                font-size: 11px;
                margin-top: 5px;
                overflow-x: auto;
              ">#{escape_html(stack)}</pre>
            </details>
          HTML
        end
        
        # ビルドエラー用の HUD HTML
        def build_error_html(error_message)
          <<~HTML
            <div style="
              position: fixed;
              inset: 0;
              background: rgba(0, 0, 0, 0.9);
              z-index: 99999;
              display: flex;
              align-items: center;
              justify-content: center;
              padding: 40px;
            ">
              <div style="
                background: #1a1a2e;
                border: 2px solid #ff6b6b;
                border-radius: 12px;
                padding: 30px;
                max-width: 800px;
                width: 100%;
                max-height: 80vh;
                overflow: auto;
              ">
                <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px;">
                  <span style="font-size: 32px;">🚨</span>
                  <h2 style="margin: 0; color: #ff6b6b; font-size: 20px;">
                    SSR Build Failed
                  </h2>
                </div>
                <pre style="
                  background: #0d0d1a;
                  color: #ff6b6b;
                  padding: 20px;
                  border-radius: 8px;
                  overflow-x: auto;
                  font-size: 13px;
                  line-height: 1.6;
                  margin: 0;
                  white-space: pre-wrap;
                  word-break: break-word;
                ">#{escape_html(error_message)}</pre>
                <p style="margin: 20px 0 0 0; color: #888; font-size: 13px;">
                  Fix the error and save the file. The page will reload automatically.
                </p>
              </div>
            </div>
          HTML
        end

        def default_bundle_path
          File.join(Dir.pwd, "vendor", "server", "ssr_bundle.js")
        end

        def require_quickjs!
          require "quickjs"
        rescue LoadError
          raise Error, <<~MSG
            quickjs gem is not installed.
            
            Add to your Gemfile:
              gem 'quickjs'
            
            Then run:
              bundle install
          MSG
        end

        def escape_js(str)
          str.to_s.gsub(/['\\]/) { |c| "\\#{c}" }
        end
        
        def escape_html(str)
          str.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub('"', "&quot;")
        end
        
        # ロギングヘルパー
        def log_info(msg)
          if defined?(Salvia.logger)
            Salvia.logger.info(msg)
          else
            puts "[SSR] #{msg}"
          end
        end
        
        def log_warn(msg)
          if defined?(Salvia.logger)
            Salvia.logger.warn(msg)
          else
            puts "[SSR WARNING] #{msg}"
          end
        end
        
        def log_error(msg)
          if defined?(Salvia.logger)
            Salvia.logger.error(msg)
          else
            puts "[SSR ERROR] #{msg}"
          end
        end
        
        def log_debug(msg)
          if defined?(Salvia.logger)
            Salvia.logger.debug(msg)
          else
            puts "[SSR DEBUG] #{msg}" if ENV["DEBUG"]
          end
        end
    end
  end
end