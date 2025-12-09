# frozen_string_literal: true

require "json"

module Salvia
  module SSR
    module Adapters
      # QuickJS (C拡張) アダプター
      # gem 'quickjs' を使用
      #
      # @example
      #   Salvia::SSR.configure(:quickjs_native)
      #   html = Salvia::SSR.render("MyComponent", { title: "Hello" })
      #
      class QuickJSNative < BaseAdapter
        def setup!
          require_quickjs!
          
          # quickjs gem はシンプルな Quickjs.eval_code API を提供
          # コンテキストはグローバルに保持される
          @js_state = ""
          
          # Preact SSR ランタイムをロード
          load_preact_runtime!
          
          # コンポーネントレジストリを初期化
          eval_js("globalThis.components = {};")
          
          mark_initialized!
        end

        def render(component_name, props = {})
          raise Error, "Engine not initialized" unless initialized?

          js_code = <<~JS
            (function() {
              const Component = globalThis.components['#{escape_js(component_name)}'];
              if (!Component) {
                throw new Error('Component not found: #{escape_js(component_name)}');
              }
              const props = #{props.to_json};
              return preactRenderToString.render(Component(props));
            })()
          JS

          begin
            eval_js(js_code)
          rescue => e
            raise RenderError, "Failed to render #{component_name}: #{e.message}"
          end
        end

        def register_component(name, code)
          raise Error, "Engine not initialized" unless initialized?

          # コンポーネントをステートに追加して登録
          @js_state += "\n#{code}\n"
          @js_state += "globalThis.components['#{escape_js(name)}'] = #{name};\n"
        end

        def shutdown!
          @js_state = ""
          @initialized = false
        end

        def engine_name
          "QuickJS (Native/C Extension)"
        end

        private

        def eval_js(code)
          # 毎回フルステートで評価 (quickjs gem の制約)
          full_code = @js_state + "\n" + code
          ::Quickjs.eval_code(full_code)
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

        def load_preact_runtime!
          runtime_path = File.join(vendor_path, "ssr-runtime.js")
          
          if File.exist?(runtime_path)
            @js_state = File.read(runtime_path)
          else
            # インラインでミニマルなランタイムを提供
            load_minimal_runtime!
          end
        end

        def load_minimal_runtime!
          # esm.sh からダウンロードした内容を使う代わりに、
          # 最小限のランタイムをインラインで定義
          minimal_runtime = <<~JS
            // Minimal Preact-like SSR runtime for QuickJS
            var htm = (function() {
              function h(type, props, ...children) {
                return { type, props: props || {}, children: children.flat() };
              }
              
              function html(strings, ...values) {
                // 簡易 HTM パーサー (本番では完全版を使用)
                let result = '';
                strings.forEach((str, i) => {
                  result += str + (values[i] !== undefined ? values[i] : '');
                });
                return parseHTM(result);
              }
              
              function parseHTM(str) {
                // 簡易パース - 実際は htm ライブラリを使用
                return { raw: str };
              }
              
              html.h = h;
              return { html, h };
            })();

            var preactRenderToString = (function() {
              function render(vnode) {
                if (vnode === null || vnode === undefined) return '';
                if (typeof vnode === 'string' || typeof vnode === 'number') return String(vnode);
                if (vnode.raw) return vnode.raw; // 簡易パース結果
                
                const { type, props, children } = vnode;
                
                if (typeof type === 'function') {
                  // 関数コンポーネント
                  return render(type(props));
                }
                
                // HTML要素
                let html = '<' + type;
                for (const [key, value] of Object.entries(props || {})) {
                  if (key === 'children') continue;
                  if (value === true) html += ' ' + key;
                  else if (value !== false && value != null) {
                    html += ' ' + key + '="' + escapeHtml(String(value)) + '"';
                  }
                }
                html += '>';
                
                // void要素
                const voidElements = ['area','base','br','col','embed','hr','img','input','link','meta','source','track','wbr'];
                if (voidElements.includes(type)) return html;
                
                // 子要素
                for (const child of (children || [])) {
                  html += render(child);
                }
                
                html += '</' + type + '>';
                return html;
              }
              
              function escapeHtml(str) {
                return str
                  .replace(/&/g, '&amp;')
                  .replace(/</g, '&lt;')
                  .replace(/>/g, '&gt;')
                  .replace(/"/g, '&quot;');
              }
              
              return { render };
            })();
          JS

          @js_state = minimal_runtime
        end

        def vendor_path
          @options[:vendor_path] || File.join(Dir.pwd, "vendor", "javascript", "server")
        end

        def escape_js(str)
          str.to_s.gsub(/['\\]/) { |c| "\\#{c}" }
        end
      end
    end
  end
end
