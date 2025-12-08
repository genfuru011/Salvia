import { render } from 'htm/preact';
import { html } from 'htm/preact';

// Island コンポーネントをマウントする
document.addEventListener('DOMContentLoaded', async () => {
  const islands = document.querySelectorAll('[data-island]');
  
  for (const island of islands) {
    const name = island.dataset.island;
    const props = JSON.parse(island.dataset.props || '{}');
    
    try {
      // 動的インポート
      // 注意: Import Map で定義された名前で import する
      const module = await import(name);
      const Component = module[name] || module.default;
      
      if (Component) {
        render(html`<${Component} ...${props} />`, island);
        console.log(`🏝️ Island mounted: ${name}`);
      } else {
        console.error(`Island component ${name} not found in module`);
      }
    } catch (error) {
      console.error(`Failed to load island: ${name}`, error);
    }
  }
});
