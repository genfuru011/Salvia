# 📝 Salvia v0.6.0+ リファクタリング TODO

---

## Phase 1: 削除

### 1.1 レンダリング関連
```
❌ salvia_rb/lib/salvia_rb/import_map.rb
❌ salvia_rb/lib/salvia_rb/helpers/import_map.rb
❌ salvia_rb/lib/salvia_rb/helpers/htmx.rb
❌ salvia_rb/lib/salvia_rb/plugins/htmx.rb
❌ CLI の htmx.min.js / importmap.rb 生成コード
```

### 1.2 SSR アダプター
```
✅ quickjs_hybrid.rb  → 残す (リネーム: QuickJS)
❌ quickjs_native.rb  → 削除 (重複)
❌ quickjs_wasm.rb    → 削除 (未使用)
❌ deno.rb            → 削除 (未使用)
❌ benchmark/         → 削除 (実験用)
```

---

## Phase 2: リファクタリング

- [ ] SSR クラス名統一 (`QuickJSNative` → `QuickJS`)
- [ ] helpers 整理 (不要なもの削除)
- [ ] plugins 整理 (HTMX 削除後)
- [ ] require 文の整理
- [ ] ドキュメントから HTMX / Import Map 言及削除

---

## Phase 3: ファイル整理

**整理後の構造:**
```
salvia_rb/lib/salvia_rb/
├── application.rb
├── controller.rb
├── router.rb
├── database.rb
├── cli.rb              # リニューアル
├── ssr.rb
├── ssr/
│   └── quickjs.rb      # 統一 (1ファイルのみ)
├── helpers/
│   ├── tag.rb
│   ├── island.rb
│   └── component.rb
└── plugins/
    ├── base.rb
    └── inspector.rb    # 開発用のみ
```

---

## Phase 4: CLI リニューアル

**参考**: Vite, Hono, create-next-app

```bash
$ salvia new my-app

🌿 Creating Salvia app...

? What would you like to build?
  ❯ Full app (ERB + Islands + DB)
    API only
    Minimal

? Include Islands? (Y/n)

✓ Created my-app/
✓ Installing dependencies...
✓ Building Islands...
✓ Setting up database...

Done! 🎉
```

**自動化:**
- Islands ビルド → サーバー起動時に自動
- ファイル監視 → 自動リビルド
- DB マイグレーション → 起動時に自動検出

**UI:**
- 英語 (CLI, ログ, エラー)

---

## Phase 5: salvia-core 切り出し

**コンセプト**: SSR Islands エンジンを独立 gem として切り出し

### gem 構成
```
salvia-core/                    ← 独立 gem (SSR Islands エンジン)
├── lib/salvia_core/
│   ├── ssr.rb
│   ├── ssr/quickjs.rb
│   ├── helpers/island.rb
│   ├── adapters/              # マルチライブラリ対応
│   │   ├── preact.rb
│   │   ├── react.rb
│   │   ├── vue.rb
│   │   ├── solid.rb
│   │   └── svelte.rb
│   ├── railtie.rb             # Rails 統合
│   └── sinatra.rb             # Sinatra 統合
└── salvia_core.gemspec

salvia/                         ← フルスタック MVC
├── lib/salvia/
│   ├── application.rb
│   ├── router.rb
│   ├── controller.rb
│   └── cli.rb
├── depends on: salvia-core
└── salvia.gemspec
```

### フレームワーク互換性

| フレームワーク | 使用方法 |
|---------------|---------|
| **Rails** | `gem "salvia-core"` + Railtie 自動登録 |
| **Sinatra** | `register SalviaCore::Sinatra` |
| **Hanami** | View helper 登録 |
| **Roda** | plugin として |
| **Rack** | 直接使用 |
| **Salvia** | 内包 (変化なし) |

### マルチライブラリ対応

| ライブラリ | SSR | Hydration | サイズ |
|-----------|-----|-----------|--------|
| **Preact** | ✅ | ✅ | 3KB (デフォルト) |
| **React** | ✅ | ✅ | 大規模向け |
| **Vue** | ✅ | ✅ | Vue ユーザー |
| **Solid** | ✅ | ✅ | 高速 |
| **Svelte** | ✅ | ✅ | コンパイル済み |

```ruby
# 設定例
SalviaCore.configure do |config|
  config.adapter = :preact  # or :react, :vue, :solid, :svelte
  config.islands_path = "app/islands"
  config.ssr_bundle = "vendor/server/ssr_bundle.js"
end
```

---

## Phase 6: ドキュメント整理

**現状 → 整理後:**
```
docs/                          docs/
├── design/                    ├── ARCHITECTURE.md  # 設計・内部構造
│   ├── ARCHITECTURE.md   →   ├── GUIDE.md         # 使い方・セキュリティ
│   ├── Idea.md                └── ROADMAP.md       # 開発計画
│   └── Strategy.md
├── development/           ルートに残す:
│   ├── IMPLEMENTATION.md      ├── README.md
│   └── ROADMAP.md             ├── CHANGELOG.md
├── meta/                      └── LICENSE
│   └── AGENTS.md
└── security/
    ├── SECURITY_*.md (4つ)
```

---

## 方針まとめ

| 項目 | 方針 |
|------|------|
| **言語** | 英語 (CLI, ログ, エラー) |
| **レンダリング** | ERB + SSR Islands のみ |
| **CLI** | 対話式、モダン UX |
| **ビルド** | 自動 (監視 & リビルド) |
| **パッケージ** | JSR 優先、なければ npm:/esm.sh |
| **設計** | salvia-core を独立、フレームワーク非依存 |
| **ドキュメント** | docs/ 内は 3 ファイルに統合 |

---

## 最終アーキテクチャ

```
salvia-core (gem)
├── QuickJS SSR エンジン
├── マルチライブラリアダプター (Preact/React/Vue/Solid/Svelte)
├── island() ヘルパー
├── Rails/Sinatra/etc 統合
└── Deno ビルドスクリプト
    ↑
salvia (gem)
├── salvia-core を依存
├── Router / Controller
├── CLI (対話式)
└── ActiveRecord 統合
    ↑
salvia new my-app
├── ERB + Islands
├── 自動ビルド
└── モダン DX
```

**対応組み合わせ例:**
- Rails + React
- Sinatra + Vue
- Hanami + Solid
- Salvia + Preact
- Rack + Svelte
