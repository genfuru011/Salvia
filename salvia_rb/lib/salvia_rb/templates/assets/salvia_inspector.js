/**
 * Salvia Island Inspector
 * 開発モード専用のデバッグツール
 * 
 * Features:
 * - Island コンポーネントのホバーハイライト
 * - コンポーネント名と Props の表示
 * - クリックで詳細パネルを表示
 */

(function() {
  'use strict';

  // 開発モードチェック
  if (!document.querySelector('[data-salvia-debug]')) {
    return;
  }

  console.log('🏝️ Salvia Island Inspector loaded');

  // ツールチップを作成
  function createTooltip(island) {
    const name = island.dataset.salviaComponent || island.dataset.island || 'Unknown';
    
    const tooltip = document.createElement('div');
    tooltip.className = 'salvia-island-tooltip';
    tooltip.textContent = `🏝️ ${name}`;
    
    island.appendChild(tooltip);
    
    return tooltip;
  }

  // Props パネルを表示
  function showPropsPanel(island) {
    const name = island.dataset.salviaComponent || island.dataset.island || 'Unknown';
    const propsJson = island.dataset.props || '{}';
    
    let props;
    try {
      props = JSON.parse(propsJson);
    } catch (e) {
      props = { _error: 'Failed to parse props', raw: propsJson };
    }

    // オーバーレイを作成
    const overlay = document.createElement('div');
    overlay.className = 'salvia-island-props-overlay';
    overlay.onclick = (e) => {
      if (e.target === overlay) {
        overlay.remove();
      }
    };

    // パネルを作成
    const panel = document.createElement('div');
    panel.className = 'salvia-island-props-panel';
    panel.innerHTML = `
      <div class="salvia-island-props-header">
        <div class="salvia-island-props-title">
          <span class="icon">🏝️</span>
          <span>${escapeHtml(name)}</span>
        </div>
        <button class="salvia-island-props-close" title="Close">&times;</button>
      </div>
      <div class="salvia-island-props-content">
        <pre>${escapeHtml(JSON.stringify(props, null, 2))}</pre>
      </div>
    `;

    panel.querySelector('.salvia-island-props-close').onclick = () => {
      overlay.remove();
    };

    overlay.appendChild(panel);
    document.body.appendChild(overlay);

    // ESC で閉じる
    const handleEsc = (e) => {
      if (e.key === 'Escape') {
        overlay.remove();
        document.removeEventListener('keydown', handleEsc);
      }
    };
    document.addEventListener('keydown', handleEsc);
  }

  // HTML エスケープ
  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  // 全ての Island にツールチップを追加
  function initIslands() {
    const islands = document.querySelectorAll('.salvia-island, [data-island]');
    
    islands.forEach(island => {
      // 既に初期化済みならスキップ
      if (island.dataset.salviaInspectorInit) return;
      island.dataset.salviaInspectorInit = 'true';

      // ツールチップを追加
      createTooltip(island);

      // Alt + クリックで Props パネルを表示
      island.addEventListener('click', (e) => {
        if (e.altKey) {
          e.preventDefault();
          e.stopPropagation();
          showPropsPanel(island);
        }
      });
    });
  }

  // 開発モードインジケーターを追加
  function addDevIndicator() {
    const indicator = document.createElement('div');
    indicator.className = 'salvia-dev-indicator';
    indicator.innerHTML = '<span class="dot"></span>Salvia Dev';
    indicator.title = 'Alt + Click on any Island to inspect props';
    
    indicator.onclick = () => {
      alert(
        '🏝️ Salvia Island Inspector\\n\\n' +
        '• Hover over Islands to see component names\\n' +
        '• Alt + Click to inspect props\\n' +
        '• Press ESC to close the props panel'
      );
    };
    
    document.body.appendChild(indicator);
  }

  // DOM 変更を監視 (動的に追加される Island 対応)
  function observeDOM() {
    const observer = new MutationObserver((mutations) => {
      let shouldInit = false;
      
      mutations.forEach(mutation => {
        if (mutation.addedNodes.length > 0) {
          shouldInit = true;
        }
      });
      
      if (shouldInit) {
        initIslands();
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  // 初期化
  function init() {
    initIslands();
    addDevIndicator();
    observeDOM();
  }

  // DOMContentLoaded または即時実行
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
