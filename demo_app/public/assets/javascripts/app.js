// Salvia アプリのカスタム JavaScript

// HTMX の設定（オプション）
document.addEventListener('htmx:configRequest', (event) => {
  // CSRF トークンを HTMX リクエストに追加
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (csrfToken) {
    event.detail.headers['X-CSRF-Token'] = csrfToken;
  }
});

// 開発環境で HTMX イベントをログ出力
if (window.location.hostname === 'localhost') {
  document.addEventListener('htmx:afterSwap', (event) => {
    console.log('HTMX swap:', event.detail.target);
  });
}
