# frozen_string_literal: true

module Salvia
  module Helpers
    # Island Inspector ヘルパー
    #
    # 開発モードで Island コンポーネントをデバッグするための
    # ツールを提供します。
    module Inspector
      # Island Inspector のスクリプトとスタイルを読み込むタグを生成
      #
      # @return [String] script タグと style タグ
      def island_inspector_tags
        return "" unless Salvia.development? && Salvia.config.island_inspector?
        
        css = inspector_css
        js = inspector_js
        
        "<style>#{css}</style>\n<script>#{js}</script>"
      end

      private

      def inspector_css
        <<~CSS
          .salvia-island-highlight {
            outline: 2px dashed #6B46C1 !important;
            outline-offset: 2px;
            position: relative;
          }
          
          .salvia-island-highlight::after {
            content: attr(data-island);
            position: absolute;
            top: -20px;
            left: 0;
            background: #6B46C1;
            color: white;
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: ui-monospace, monospace;
            z-index: 10000;
            pointer-events: none;
          }
          
          .salvia-inspector-panel {
            position: fixed;
            bottom: 20px;
            right: 20px;
            width: 320px;
            max-height: 400px;
            background: #1e1e1e;
            color: #d4d4d4;
            border-radius: 8px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
            font-family: ui-monospace, monospace;
            font-size: 12px;
            z-index: 10001;
            overflow: hidden;
          }
          
          .salvia-inspector-header {
            background: #6B46C1;
            color: white;
            padding: 8px 12px;
            font-weight: bold;
            display: flex;
            justify-content: space-between;
            align-items: center;
          }
          
          .salvia-inspector-close {
            background: none;
            border: none;
            color: white;
            cursor: pointer;
            font-size: 16px;
            padding: 0 4px;
          }
          
          .salvia-inspector-content {
            padding: 12px;
            max-height: 340px;
            overflow-y: auto;
          }
          
          .salvia-inspector-section {
            margin-bottom: 12px;
          }
          
          .salvia-inspector-label {
            color: #9cdcfe;
            margin-bottom: 4px;
          }
          
          .salvia-inspector-value {
            background: #2d2d2d;
            padding: 6px 8px;
            border-radius: 4px;
            word-break: break-all;
          }
          
          .salvia-inspector-json {
            white-space: pre-wrap;
            color: #ce9178;
          }
        CSS
      end

      def inspector_js
        <<~JS
          (function() {
            let currentPanel = null;
            
            // Alt + Click でパネルを表示
            document.addEventListener('click', function(e) {
              if (!e.altKey) return;
              
              const island = e.target.closest('[data-island]');
              if (!island) return;
              
              e.preventDefault();
              e.stopPropagation();
              
              showInspectorPanel(island);
            });
            
            // ホバー時にハイライト
            document.addEventListener('mouseover', function(e) {
              const island = e.target.closest('[data-island]');
              if (island) {
                island.classList.add('salvia-island-highlight');
              }
            });
            
            document.addEventListener('mouseout', function(e) {
              const island = e.target.closest('[data-island]');
              if (island) {
                island.classList.remove('salvia-island-highlight');
              }
            });
            
            function showInspectorPanel(island) {
              if (currentPanel) {
                currentPanel.remove();
              }
              
              const name = island.dataset.island;
              const props = JSON.parse(island.dataset.props || '{}');
              const ssr = island.dataset.ssr === 'true';
              const hydrated = island.dataset.hydrated === 'true';
              
              const panel = document.createElement('div');
              panel.className = 'salvia-inspector-panel';
              panel.innerHTML = `
                <div class="salvia-inspector-header">
                  <span>🏝️ \${name}</span>
                  <button class="salvia-inspector-close">×</button>
                </div>
                <div class="salvia-inspector-content">
                  <div class="salvia-inspector-section">
                    <div class="salvia-inspector-label">SSR</div>
                    <div class="salvia-inspector-value">\${ssr ? '✅ Yes' : '❌ No'}</div>
                  </div>
                  <div class="salvia-inspector-section">
                    <div class="salvia-inspector-label">Hydrated</div>
                    <div class="salvia-inspector-value">\${hydrated ? '✅ Yes' : '⏳ Pending'}</div>
                  </div>
                  <div class="salvia-inspector-section">
                    <div class="salvia-inspector-label">Props</div>
                    <div class="salvia-inspector-value salvia-inspector-json">\${JSON.stringify(props, null, 2)}</div>
                  </div>
                </div>
              `;
              
              panel.querySelector('.salvia-inspector-close').addEventListener('click', function() {
                panel.remove();
                currentPanel = null;
              });
              
              document.body.appendChild(panel);
              currentPanel = panel;
            }
            
            console.log('🔍 Salvia Island Inspector: Alt+Click on any island to inspect');
          })();
        JS
      end
    end
  end
end
