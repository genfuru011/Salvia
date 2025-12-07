# Salvia.rb Roadmap

> "Wisdom for Rubyists." — HTMX × Tailwind × ActiveRecord を前提にした、小さくて理解しやすい Ruby MVC フレームワーク

---

## Vision

Salvia.rb は「Rails は重すぎる、Sinatra は軽すぎる」という隙間を埋めるフレームワークです。

- **サーバーレンダリング (HTML) ファースト**
- **HTMX による部分更新**が基本
- **Tailwind CSS** でモダンな見た目
- **ActiveRecord** でデータベース操作
- **Node.js 不要**（tailwindcss-ruby を使用）

---

## Phase 0: Foundation (v0.1.0) ✅

最初のマイルストーン。「動くデモ」を作れる最小限の機能セット。

### Core Framework
- [x] `Salvia::Application` - Rack アプリケーション基底クラス
- [x] `Salvia::Router` - Rails ライクな DSL ルーティング（Mustermann ベース）
- [x] `Salvia::Controller` - リクエスト/レスポンス処理の基底クラス
- [x] `render` メソッド - ERB テンプレートのレンダリング
- [x] レイアウト + パーシャルのサポート

### Database
- [x] `Salvia::Database` - ActiveRecord 接続管理
- [x] `config/database.yml` の読み込み
- [x] `ApplicationRecord` 基底クラス生成

### CLI
- [x] `salvia new APP_NAME` - アプリケーション雛形の生成
- [x] `salvia server` (`salvia s`) - 開発サーバー起動
- [x] `salvia db:migrate` - マイグレーション実行
- [x] `salvia css:build` - Tailwind CSS ビルド

### Assets
- [x] HTMX (htmx.min.js) の自動配置
- [x] Tailwind CSS の初期設定

---

## Phase 1: Developer Experience (v0.2.0)

開発者体験の向上。コードリロードとスマートなレンダリング。

### Smart Rendering
- [ ] `htmx_request?` ヘルパー
- [ ] HTMX リクエスト時の自動レイアウト除外
- [ ] `render` メソッドの統一（view/partial の自動判定）

### Auto-reloading
- [ ] Zeitwerk によるオートローディング
- [ ] 開発環境でのコードリロード

### Error Handling
- [ ] 開発用エラー画面（スタックトレース表示）
- [ ] 本番用エラーページ (404, 500)

### CLI Enhancement
- [ ] `salvia console` (`salvia c`) - IRB コンソール
- [ ] `salvia css:watch` - Tailwind ウォッチモード
- [ ] `salvia db:create` / `salvia db:setup`

---

## Phase 2: Security & Stability (v0.3.0)

セキュリティ機能とセッション管理。本番利用に向けた基盤。

### Security
- [ ] CSRF 対策（Rack::Protection 統合）
- [ ] HTMX 用 CSRF トークン自動送信設定
- [ ] `<meta name="csrf-token">` ヘルパー

### Session Management
- [ ] Cookie ベースセッション（Rack::Session::Cookie）
- [ ] `session` ヘルパー
- [ ] `flash` メッセージ（flash[:notice], flash[:alert]）

### Routing Enhancement
- [ ] `resources` DSL の完全実装
- [ ] ネストしたリソース
- [ ] 名前付きルート（`*_path` ヘルパー）

---

## Phase 3: Production Ready (v0.4.0 → v1.0.0)

本番運用に必要な機能。v1.0.0 での安定リリースを目指す。

### Asset Management
- [ ] アセットダイジェスト（キャッシュバスティング）
- [ ] `asset_path` ヘルパー
- [ ] 本番用アセット圧縮

### Logging & Monitoring
- [ ] リクエストロギング
- [ ] カスタムロガー設定
- [ ] エラーレポート用フック

### Testing Support
- [ ] Controller テストヘルパー
- [ ] HTMX リクエストのモック
- [ ] 統合テストサポート（Capybara 連携ガイド）

### Documentation
- [ ] Getting Started ガイド
- [ ] API リファレンス
- [ ] デプロイガイド（Render, Fly.io, Heroku）

---

## Future (v1.x+)

v1.0 以降の拡張機能。

### HTMX Helpers
- [ ] `htmx_link_to` ヘルパー
- [ ] `htmx_form_for` ヘルパー
- [ ] `htmx_trigger` レスポンスヘッダー設定

### View Components
- [ ] `component` ヘルパー
- [ ] Tailwind クラスのカプセル化
- [ ] UI プリセット（Button, Card, Modal）

### Advanced Features
- [ ] WebSocket サポート（ActionCable 的な）
- [ ] バックグラウンドジョブ統合ガイド
- [ ] マルチテナント対応

---

## 🏝️ Salvia Islands (v2.x - 長期目標)

> **"HTML ファーストを維持しながら、必要な部分だけリッチに"**
>
> Node.js 不要で Island Architecture を実現する革命的アプローチ

### コンセプト

```
┌─────────────────────────────────────────────────────────┐
│              Salvia (HTML + HTMX)                       │
│  ┌─────────────────────────────────────────────────┐   │
│  │  90% サーバーレンダリング（従来通り）           │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────────────┐ │   │
│  │  │ Island  │  │ Island  │  │     HTML        │ │   │
│  │  │ (Chart) │  │(Editor) │  │   (HTMX で十分) │ │   │
│  │  └─────────┘  └─────────┘  └─────────────────┘ │   │
│  │  10% クライアントサイド（複雑なUIのみ）        │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 技術スタック

**Node.js 不要** を維持するため、以下の2つのアプローチを採用：

#### Option B: Web Components (Lit / Vanilla)
```erb
<!-- ブラウザネイティブ、軽量 -->
<%= island "chart-component", { data: @sales_data } %>
```
- **Lit** (5KB) または Vanilla Web Components
- Shadow DOM でスタイル分離
- ブラウザ標準技術

#### Option C: Import Maps + ESM (ビルドレス)
```html
<!-- config.ru または layout で設定 -->
<script type="importmap">
{
  "imports": {
    "lit": "https://esm.sh/lit@3",
    "chart.js": "https://esm.sh/chart.js@4"
  }
}
</script>
```
- CDN から直接 import（esm.sh, unpkg）
- 開発時ビルド不要
- Deno Fresh / Astro に近いアプローチ

### 実装計画

#### Phase A: 基盤 (v2.0)
- [ ] `island` ビューヘルパー
- [ ] Import Maps の自動生成
- [ ] Props の JSON シリアライズ
- [ ] 基本的な Web Component テンプレート

#### Phase B: 統合 (v2.1)
- [ ] HTMX `afterSwap` での Island 自動再マウント
- [ ] Lazy Loading（Intersection Observer）
- [ ] SSR フォールバック（SEO 対策）

#### Phase C: エコシステム (v2.2)
- [ ] 公式 Island コンポーネント集
  - `<salvia-chart>` - Chart.js ラッパー
  - `<salvia-editor>` - リッチテキストエディタ
  - `<salvia-calendar>` - カレンダー
  - `<salvia-autocomplete>` - オートコンプリート
- [ ] Island Component Generator (`salvia g island NAME`)

### 使用イメージ

```erb
<!-- app/views/dashboard/index.html.erb -->
<div class="dashboard">
  <h1>ダッシュボード</h1>
  
  <!-- 普通の HTMX（これで十分な部分） -->
  <div hx-get="/notifications" hx-trigger="every 30s">
    <%= render "notifications/_list" %>
  </div>

  <!-- 複雑なインタラクションが必要な部分だけ Island -->
  <%= island "salvia-chart", { 
    data: @sales_data, 
    type: "line",
    title: "月間売上" 
  } %>
  
  <!-- 遅延読み込み（スクロールで表示時に初期化） -->
  <%= island "salvia-calendar", { events: @events }, lazy: true %>
  
  <!-- カスタム Island -->
  <%= island "my-rich-editor", { content: @draft.body } %>
</div>
```

### なぜ革命的か

| 従来 | Salvia Islands |
|------|----------------|
| SPA vs SSR の二択 | 両方のいいとこ取り |
| React なら全部 React | 必要な所だけ JS |
| npm/webpack 必須 | **Node.js 不要** |
| 複雑なビルド設定 | Import Maps でシンプル |
| Ruby と JS の分断 | ERB から自然に統合 |

### 参考にする既存技術

- **Astro** - Island Architecture の先駆者
- **Deno Fresh** - Import Maps + Preact
- **Hotwire (Turbo/Stimulus)** - Rails の部分的 JS
- **htmx** - HTML ファーストの思想

---

## Version Policy

- **0.x.x**: 実験的リリース。破壊的変更あり
- **1.0.0**: 安定版。Semantic Versioning に従う
- **1.x.x**: 後方互換性を維持

---

## Contributing

Salvia.rb はオープンソースプロジェクトです。
Issue や Pull Request でのコントリビューションを歓迎します。

---

*最終更新: 2025-01*

