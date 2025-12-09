# frozen_string_literal: true

require "json"
require "open3"
require "tempfile"

module Salvia
  module SSR
    module Adapters
      # Deno アダプター
      # システムにインストールされた deno コマンドを使用
      #
      # メリット:
      # - TypeScript / JSX をネイティブサポート
      # - JSR (JavaScript Registry) を直接利用可能
      # - 高いセキュリティ (パーミッションシステム)
      #
      # デメリット:
      # - Deno の別途インストールが必要
      # - 外部プロセス起動のオーバーヘッド
      #
      # @example
      #   Salvia::SSR.configure(:deno)
      #   html = Salvia::SSR.render("MyComponent", { title: "Hello" })
      #
      class Deno < BaseAdapter
        # 登録済みコンポーネントのキャッシュ
        attr_reader :components

        def setup!
          check_deno_installed!
          ensure_ssr_runner!
          
          @components = {}
          @deno_version = detect_deno_version
          
          mark_initialized!
        end

        def render(component_name, props = {})
          raise Error, "Engine not initialized" unless initialized?

          component_path = @components[component_name]
          
          unless component_path
            # islands ディレクトリから自動検出
            component_path = find_component_file(component_name)
            raise RenderError, "Component not found: #{component_name}" unless component_path
          end

          input = {
            component: component_name,
            componentPath: component_path,
            props: props
          }.to_json

          # Open3.popen3 を使って stdin にデータを書き込む
          stdout_str = ""
          stderr_str = ""
          status = nil

          Open3.popen3(
            "deno", "run",
            "--allow-read=#{components_path},#{vendor_path}",
            "--allow-net=esm.sh,cdn.jsdelivr.net",
            "--quiet",
            ssr_runner_path
          ) do |stdin, stdout, stderr, wait_thr|
            stdin.write(input)
            stdin.close
            stdout_str = stdout.read
            stderr_str = stderr.read
            status = wait_thr.value
          end

          unless status.success?
            raise RenderError, "Deno SSR failed: stderr=#{stderr_str}, stdout=#{stdout_str}"
          end

          begin
            result = JSON.parse(stdout_str)
          rescue JSON::ParserError => e
            raise RenderError, "Invalid JSON from Deno: #{stdout_str[0..200]}"
          end
          
          if result["error"]
            raise RenderError, "Failed to render #{component_name}: #{result['error']}"
          end

          result["html"]
        end

        def register_component(name, code_or_path)
          raise Error, "Engine not initialized" unless initialized?

          if File.exist?(code_or_path)
            # ファイルパスの場合
            @components[name] = File.expand_path(code_or_path)
          else
            # コード文字列の場合 → 一時ファイルに保存
            tempfile = Tempfile.new(["#{name}_", ".tsx"])
            tempfile.write(code_or_path)
            tempfile.close
            @components[name] = tempfile.path
            # Note: tempfile は GC されると削除される
          end
        end

        def shutdown!
          @components = {}
          @initialized = false
        end

        def engine_name
          "Deno #{@deno_version || '(unknown version)'}"
        end

        private

        def check_deno_installed!
          stdout, _, status = Open3.capture3("deno", "--version")
          
          unless status.success?
            raise Error, <<~MSG
              Deno is not installed or not in PATH.
              
              Install Deno:
                curl -fsSL https://deno.land/install.sh | sh
              
              Or visit: https://deno.land
            MSG
          end
        end

        def detect_deno_version
          stdout, _, status = Open3.capture3("deno", "--version")
          return nil unless status.success?
          
          # "deno 1.40.0 (release, ...)" から "1.40.0" を抽出
          if stdout =~ /deno (\d+\.\d+\.\d+)/
            $1
          end
        end

        def ensure_ssr_runner!
          unless File.exist?(ssr_runner_path)
            create_ssr_runner!
          end
        end

        def create_ssr_runner!
          FileUtils.mkdir_p(File.dirname(ssr_runner_path))
          
          runner_code = <<~TYPESCRIPT
            // Salvia SSR Runner for Deno
            // Auto-generated - do not edit manually
            
            import { renderToString } from "npm:preact-render-to-string@6";
            import { h } from "npm:preact@10";
            import htm from "npm:htm@3";

            const html = htm.bind(h);

            // stdin から JSON を読み取る
            const decoder = new TextDecoder();
            const chunks: Uint8Array[] = [];

            for await (const chunk of Deno.stdin.readable) {
              chunks.push(chunk);
            }

            const input = JSON.parse(decoder.decode(new Uint8Array(chunks.flat())));
            const { component, componentPath, props } = input;

            try {
              // コンポーネントを動的インポート
              const moduleUrl = componentPath.startsWith("file://") 
                ? componentPath 
                : `file://${componentPath}`;
              
              const module = await import(moduleUrl);
              const Component = module.default || module[component];

              if (!Component) {
                throw new Error(`Component "${component}" not found in module`);
              }

              // SSR 実行
              const element = h(Component, props);
              const htmlResult = renderToString(element);

              console.log(JSON.stringify({ html: htmlResult }));
            } catch (error) {
              console.log(JSON.stringify({ 
                error: error instanceof Error ? error.message : String(error) 
              }));
              Deno.exit(1);
            }
          TYPESCRIPT

          File.write(ssr_runner_path, runner_code)
        end

        def find_component_file(component_name)
          # 複数の拡張子を試す
          extensions = [".tsx", ".ts", ".jsx", ".js"]
          
          extensions.each do |ext|
            path = File.join(components_path, "#{component_name}#{ext}")
            return path if File.exist?(path)
          end
          
          nil
        end

        def ssr_runner_path
          @options[:runner_path] || File.join(vendor_path, "ssr_runner.ts")
        end

        def components_path
          @options[:components_path] || File.join(Dir.pwd, "app", "islands")
        end

        def vendor_path
          @options[:vendor_path] || File.join(Dir.pwd, "vendor", "javascript")
        end
      end
    end
  end
end
