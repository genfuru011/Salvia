#!/usr/bin/env ruby
# frozen_string_literal: true

# Salvia SSR Engine Benchmark
# 
# 3つのSSRエンジン (QuickJS Native, QuickJS Wasm, Deno) を比較します。
#
# Usage:
#   cd salvia_rb
#   bundle exec ruby benchmark/ssr_benchmark.rb
#
# Requirements:
#   - gem 'quickjs' (for QuickJS Native)
#   - gem 'wasmtime' (for QuickJS Wasm)
#   - deno command (for Deno)

require "bundler/setup"
require "benchmark"
require "json"
require "fileutils"
require "tmpdir"

# salvia_rb をロード
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "salvia_rb/ssr"

module SSRBenchmark
  ITERATIONS = 50
  WARMUP_ITERATIONS = 5
  
  # テスト用のシンプルなコンポーネント
  TEST_COMPONENT_JS = <<~JS
    function TestComponent(props) {
      return {
        type: 'div',
        props: { class: 'card' },
        children: [
          { type: 'h1', props: {}, children: [props.title || 'Hello'] },
          { type: 'p', props: {}, children: ['Count: ' + (props.count || 0)] },
          { type: 'ul', props: {}, children: (props.items || []).map(function(item) {
            return { type: 'li', props: {}, children: [item] };
          })}
        ]
      };
    }
    globalThis.components = globalThis.components || {};
    globalThis.components['TestComponent'] = TestComponent;
  JS

  # Deno 用の TypeScript コンポーネント (htm を使用)
  TEST_COMPONENT_TSX = <<~TSX
    import { h } from "npm:preact@10";
    import htm from "npm:htm@3";

    const html = htm.bind(h);

    interface Props {
      title?: string;
      count?: number;
      items?: string[];
    }

    export default function TestComponent({ title = "Hello", count = 0, items = [] }: Props) {
      return html\`
        <div class="card">
          <h1>\${title}</h1>
          <p>Count: \${count}</p>
          <ul>
            \${items.map((item: string, i: number) => html\`<li key=\${i}>\${item}</li>\`)}
          </ul>
        </div>
      \`;
    }
  TSX

  TEST_PROPS = {
    title: "Benchmark Test",
    count: 42,
    items: (1..10).map { |i| "Item #{i}" }
  }.freeze

  class Runner
    def initialize
      @results = {}
      setup_test_files!
    end

    def run!
      puts header
      
      benchmark_engine(:quickjs_native, "QuickJS (C拡張)")
      benchmark_engine(:quickjs_wasm, "QuickJS (Wasm)")
      benchmark_engine(:deno, "Deno")
      
      puts summary
      
      cleanup!
    end

    private

    def header
      <<~HEADER
        
        #{'=' * 60}
        🏝️  Salvia SSR Engine Benchmark
        #{'=' * 60}
        
        Iterations: #{ITERATIONS} (+ #{WARMUP_ITERATIONS} warmup)
        Props: #{TEST_PROPS.to_json[0..50]}...
        
      HEADER
    end

    def benchmark_engine(engine, name)
      puts "-" * 60
      puts "🔧 Testing: #{name}"
      puts "-" * 60

      begin
        # エンジン初期化
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        adapter = Salvia::SSR.configure(engine, engine_options(engine))
        init_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

        puts "   Init time: #{(init_time * 1000).round(2)}ms"

        # コンポーネント登録 (Deno以外)
        unless engine == :deno
          adapter.register_component("TestComponent", TEST_COMPONENT_JS)
        end

        # ウォームアップ
        print "   Warming up..."
        WARMUP_ITERATIONS.times do
          Salvia::SSR.render("TestComponent", TEST_PROPS)
        end
        puts " done"

        # ベンチマーク
        print "   Benchmarking..."
        times = []
        
        ITERATIONS.times do
          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          html = Salvia::SSR.render("TestComponent", TEST_PROPS)
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
          times << elapsed
        end
        puts " done"

        # 結果を計算
        total = times.sum
        avg = total / times.length
        min = times.min
        max = times.max
        median = times.sort[times.length / 2]
        
        # 標準偏差
        variance = times.map { |t| (t - avg) ** 2 }.sum / times.length
        stddev = Math.sqrt(variance)

        @results[engine] = {
          success: true,
          name: name,
          init_ms: init_time * 1000,
          total_s: total,
          avg_ms: avg * 1000,
          min_ms: min * 1000,
          max_ms: max * 1000,
          median_ms: median * 1000,
          stddev_ms: stddev * 1000,
          renders_per_sec: 1.0 / avg
        }

        puts format_result(@results[engine])

      rescue Salvia::SSR::Error => e
        @results[engine] = { success: false, name: name, error: e.message }
        puts "   ❌ Failed: #{e.message}"
      rescue LoadError => e
        @results[engine] = { success: false, name: name, error: "Gem not installed: #{e.message}" }
        puts "   ⏭️  Skipped: #{e.message}"
      ensure
        Salvia::SSR.shutdown!
      end

      puts
    end

    def engine_options(engine)
      case engine
      when :deno
        { components_path: @test_components_path }
      else
        {}
      end
    end

    def format_result(result)
      <<~RESULT
        
           ✅ Success!
           ─────────────────────────────
           Total time:    #{result[:total_s].round(3)}s
           Avg per render: #{result[:avg_ms].round(3)}ms
           Median:        #{result[:median_ms].round(3)}ms
           Min:           #{result[:min_ms].round(3)}ms
           Max:           #{result[:max_ms].round(3)}ms
           Std Dev:       #{result[:stddev_ms].round(3)}ms
           Renders/sec:   #{result[:renders_per_sec].round(1)}
      RESULT
    end

    def summary
      successful = @results.select { |_, r| r[:success] }
      
      return "\n⚠️  No successful benchmarks to compare.\n" if successful.empty?

      # 最速を特定
      fastest = successful.min_by { |_, r| r[:avg_ms] }
      
      lines = [
        "",
        "=" * 60,
        "📊 Summary",
        "=" * 60,
        "",
        format("%-25s %12s %12s %12s", "Engine", "Avg (ms)", "Median (ms)", "vs Fastest"),
        "-" * 60
      ]

      successful.sort_by { |_, r| r[:avg_ms] }.each do |engine, result|
        ratio = result[:avg_ms] / fastest[1][:avg_ms]
        ratio_str = engine == fastest[0] ? "🏆 fastest" : "#{ratio.round(2)}x slower"
        
        lines << format("%-25s %12.3f %12.3f %12s",
                        result[:name],
                        result[:avg_ms],
                        result[:median_ms],
                        ratio_str)
      end

      failed = @results.reject { |_, r| r[:success] }
      unless failed.empty?
        lines << ""
        lines << "⏭️  Skipped engines:"
        failed.each do |_, result|
          lines << "   - #{result[:name]}: #{result[:error]}"
        end
      end

      lines << ""
      lines << "=" * 60
      lines << ""

      lines.join("\n")
    end

    def setup_test_files!
      @test_components_path = File.join(Dir.tmpdir, "salvia_benchmark_components")
      FileUtils.mkdir_p(@test_components_path)
      
      # Deno 用コンポーネント
      File.write(
        File.join(@test_components_path, "TestComponent.tsx"),
        TEST_COMPONENT_TSX
      )
    end

    def cleanup!
      FileUtils.rm_rf(@test_components_path) if @test_components_path
    end
  end
end

# 実行
SSRBenchmark::Runner.new.run!
