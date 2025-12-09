# frozen_string_literal: true

require "json"

module Salvia
  module SSR
    module Adapters
      # QuickJS (WebAssembly) アダプター
      # gem 'wasmtime' を使用
      #
      # 最もポータブルな選択肢：
      # - C拡張のビルドエラーが起きない
      # - Mac/Windows/Linux で同じ動作を保証
      # - 高いセキュリティ (サンドボックス)
      #
      # @example
      #   Salvia::SSR.configure(:quickjs_wasm)
      #   html = Salvia::SSR.render("MyComponent", { title: "Hello" })
      #
      class QuickJSWasm < BaseAdapter
        # QuickJS Wasm バイナリのデフォルトパス
        QUICKJS_WASM_PATH = File.expand_path("../../../../vendor/wasm/quickjs.wasm", __dir__)

        def setup!
          require_wasmtime!
          
          # Wasm エンジンを初期化
          @engine = Wasmtime::Engine.new
          @store = Wasmtime::Store.new(@engine)
          
          # QuickJS Wasm をロード
          wasm_path = @options[:wasm_path] || QUICKJS_WASM_PATH
          
          unless File.exist?(wasm_path)
            raise Error, <<~MSG
              QuickJS WASM not found at: #{wasm_path}
              
              Run the following to download:
                salvia install --runtime
              
              Or manually download from:
                https://github.com/aspect-build/aspect-quickjs/releases
            MSG
          end

          load_wasm_module!(wasm_path)
          load_preact_runtime!
          init_component_registry!
          
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
              const element = htm.html`<${Component} ...${props} />`;
              return preactRenderToString.render(element);
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

          wrapped_code = <<~JS
            (function() {
              var exports = {};
              #{code}
              if (exports.default) {
                globalThis.components['#{escape_js(name)}'] = exports.default;
              } else if (typeof #{name} !== 'undefined') {
                globalThis.components['#{escape_js(name)}'] = #{name};
              }
            })()
          JS

          eval_js(wrapped_code)
        end

        def shutdown!
          @instance = nil
          @module = nil
          @store = nil
          @engine = nil
          @initialized = false
        end

        def engine_name
          "QuickJS (WebAssembly)"
        end

        private

        def require_wasmtime!
          require "wasmtime"
        rescue LoadError
          raise Error, <<~MSG
            wasmtime gem is not installed.
            
            Add to your Gemfile:
              gem 'wasmtime'
            
            Then run:
              bundle install
          MSG
        end

        def load_wasm_module!(wasm_path)
          wasm_binary = File.binread(wasm_path)
          @module = Wasmtime::Module.new(@engine, wasm_binary)
          
          # WASI インポートを設定 (QuickJS が必要とする)
          wasi_config = Wasmtime::WasiCtxBuilder.new
            .inherit_stdout
            .inherit_stderr
            .build
          
          @store = Wasmtime::Store.new(@engine, wasi_config)
          
          # リンカーでインスタンス化
          linker = Wasmtime::Linker.new(@engine)
          linker.define_wasi
          
          @instance = linker.instantiate(@store, @module)
          
          # QuickJS の初期化関数を呼び出し
          if (init_fn = @instance.export("qjs_init")&.to_func)
            init_fn.call(@store)
          end
        end

        def eval_js(code)
          # QuickJS Wasm の eval 関数を呼び出し
          eval_fn = @instance.export("qjs_eval")&.to_func
          
          unless eval_fn
            raise Error, "QuickJS WASM does not export qjs_eval function"
          end

          # 文字列をメモリに書き込む
          memory = @instance.export("memory")&.to_memory
          alloc_fn = @instance.export("qjs_alloc")&.to_func
          free_fn = @instance.export("qjs_free")&.to_func
          
          unless memory && alloc_fn
            raise Error, "QuickJS WASM missing required exports (memory, qjs_alloc)"
          end

          # JS コードをメモリに書き込み
          code_bytes = code.encode("UTF-8").bytes
          code_ptr = alloc_fn.call(@store, code_bytes.length + 1)
          
          memory.write(@store, code_ptr, code_bytes.pack("C*") + "\x00")
          
          # eval を実行
          result_ptr = eval_fn.call(@store, code_ptr)
          
          # 結果を読み取り
          result = read_string_from_memory(memory, result_ptr)
          
          # メモリを解放
          free_fn&.call(@store, code_ptr) if free_fn
          
          result
        end

        def read_string_from_memory(memory, ptr)
          return "" if ptr == 0
          
          # NULL終端文字列を読み取り
          bytes = []
          offset = 0
          loop do
            byte = memory.read(@store, ptr + offset, 1).unpack1("C")
            break if byte == 0
            bytes << byte
            offset += 1
            break if offset > 1_000_000 # 安全のための上限
          end
          
          bytes.pack("C*").force_encoding("UTF-8")
        end

        def load_preact_runtime!
          runtime_path = File.join(vendor_path, "ssr-runtime.js")
          
          if File.exist?(runtime_path)
            eval_js(File.read(runtime_path))
          else
            load_minimal_runtime!
          end
        end

        def load_minimal_runtime!
          # QuickJS Native と同じミニマルランタイム
          minimal_runtime = <<~JS
            var htm = (function() {
              function h(type, props, ...children) {
                return { type, props: props || {}, children: children.flat() };
              }
              
              function html(strings, ...values) {
                let result = '';
                strings.forEach((str, i) => {
                  result += str + (values[i] !== undefined ? values[i] : '');
                });
                return parseHTM(result);
              }
              
              function parseHTM(str) {
                return { raw: str };
              }
              
              html.h = h;
              return { html, h };
            })();

            var preactRenderToString = (function() {
              function render(vnode) {
                if (vnode === null || vnode === undefined) return '';
                if (typeof vnode === 'string' || typeof vnode === 'number') return String(vnode);
                if (vnode.raw) return vnode.raw;
                
                const { type, props, children } = vnode;
                
                if (typeof type === 'function') {
                  return render(type(props));
                }
                
                let html = '<' + type;
                for (const [key, value] of Object.entries(props || {})) {
                  if (key === 'children') continue;
                  if (value === true) html += ' ' + key;
                  else if (value !== false && value != null) {
                    html += ' ' + key + '="' + escapeHtml(String(value)) + '"';
                  }
                }
                html += '>';
                
                const voidElements = ['area','base','br','col','embed','hr','img','input','link','meta','source','track','wbr'];
                if (voidElements.includes(type)) return html;
                
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

          eval_js(minimal_runtime)
        end

        def init_component_registry!
          eval_js("globalThis.components = {};")
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
