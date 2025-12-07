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

### Islands Architecture (Salvia Islands)
- [ ] `<%= island "ComponentName", props %>` ヘルパー
- [ ] React/Preact コンポーネントのマウント
- [ ] `salvia island:build` コマンド
- [ ] HTMX `afterSwap` での自動再マウント

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

## Version Policy

- **0.x.x**: 実験的リリース。破壊的変更あり
- **1.0.0**: 安定版。Semantic Versioning に従う
- **1.x.x**: 後方互換性を維持

---

## Contributing

Salvia.rb はオープンソースプロジェクトです。
Issue や Pull Request でのコントリビューションを歓迎します。

---

*Last updated: 2024-12*

