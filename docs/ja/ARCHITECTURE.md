# Salvia アーキテクチャ

> **Rubyのための真のHTMLファーストアーキテクチャ**

---

## 概要

Salviaは、Rubyアプリケーション (Rails) のための次世代フロントエンドエンジンです。**Islandsアーキテクチャ** と **Server Components** の概念をRubyエコシステムにもたらし、お気に入りのRubyフレームワークを捨てることなく、JSX/TSXを使用してモダンでインタラクティブなUIを構築できる「真のHTMLファースト」アプローチを可能にします。

### "ERBless" ビジョン

ReactコンポーネントをERBテンプレートに埋め込む従来のアプローチとは異なり、SalviaではViewレイヤー全体を **Server Components** (JSX/TSX) に置き換えることができます。

- **ルーティング & データ**: Ruby (Controllers) が担当。
- **Viewレイヤー**: Salvia (JSX/TSX Server Components) が担当。
- **インタラクティブ**: Islands (ハイドレーションされたクライアントコンポーネント) が担当。

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Development (JIT)                            │
│                                                                     │
│  Request ──▶ [Salvia::DevServer] ──▶ [Managed Sidecar (Deno)]       │
│                     │                          │                    │
│                     ▼                          ▼                    │
│               Asset Serving              JIT Compilation            │
│             (islands.js, etc.)           (esbuild-wasm)             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Runtime (Ruby + QuickJS)                       │
│                                                                     │
│  1. Controller: render ssr("Home", props)                           │
│                         │                                           │
│                         ▼                                           │
│  2. QuickJS: SSR.renderToString("Home", props) → HTML (0.3ms)       │
│                         │                                           │
│                         ▼                                           │
│  3. Output: <html>...<div data-island="Counter">...</div>...</html> │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Client (Browser)                             │
│                                                                     │
│  1. Load HTML (Fast FCP)                                            │
│  2. Load islands.js (Preact + Turbo)                                │
│  3. Hydrate only [data-island] elements                             │
│  4. → Interactive!                                                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ディレクトリ構造

Salviaはプロジェクトのルートに専用の `salvia/` ディレクトリを導入し、フロントエンドの関心事をバックエンドから分離しつつ、共存させます。

```
my_app/
├── app/                   # Ruby Backend (Controllers, Models)
├── config/
├── ...
└── salvia/                # Frontend Root
    ├── deno.json          # Import Map & Dependencies (SSOT)
    └── app/
        ├── pages/         # Server Components (Entry Points)
        │   ├── Home.tsx   # Replaces app/views/home/index.html.erb
        │   └── layouts/   # Shared Layouts
        ├── components/    # Shared UI Components (Server/Client)
        │   ├── Button.tsx
        │   └── Card.tsx
        └── islands/       # Client Components (Interactive)
            ├── Counter.tsx
            └── Navbar.tsx
```

---

## コアコンポーネント

### 1. SSRエンジン (`Salvia::SSR`)

**役割:** サーバー上でJavaScriptを実行し、コンポーネントをHTML文字列にレンダリングします。

- **技術:** [QuickJS](https://bellard.org/quickjs/) (`quickjs` gem経由)。
- **パフォーマンス:** 非常に高速な起動と実行 (レンダリングあたり約0.3ms)。
- **分離:** 各レンダリングはサンドボックス化されたコンテキストで実行されます。
- **DOMモッキング:** ブラウザライクな環境を期待するライブラリをサポートするために、最小限のDOM環境 (`document`, `Event`, `URL` など) を提供します。

### 2. マネージドサイドカー ("The Engine")

**役割:** Rubyアプリケーションによって管理される長時間実行のDenoプロセスで、コンパイルとツール処理を担当します。

- **ライフサイクル:** 最初のリクエスト時に `Salvia::Compiler` によって自動的に開始されます。
- **通信:** 動的に割り当てられたTCPポート (Port 0) 上のHTTP。
- **機能:**
  - **JITコンパイル:** `esbuild` を使用してTSX/JSXをオンザフライでJavaScriptにトランスパイルします。
  - **フォーマット:** `deno fmt` をRubyに公開します。
  - **型チェック:** `deno check` をRubyに公開します。
  - **インポート解決:** `deno.json` に基づいてインポートを解決します。

### 3. JITコンパイラ & DevServer

**役割:** 開発中に "No Build" 体験を可能にします。

- **`Salvia::DevServer`**: JavaScriptアセット (例: `/assets/islands/Counter.js`) へのリクエストをインターセプトするRackミドルウェア。
- **オンデマンドコンパイル:** アセットがリクエストされると、Sidecarに対応するTSXファイルのコンパイルを依頼します。
- **ソースマップ:** デバッグ用にインラインソースマップを自動的に生成します。

### 4. 依存関係管理 (インポートマップ)

**役割:** 依存関係の信頼できる唯一の情報源 (SSOT)。

- **`deno.json`**: サーバー (SSR) とクライアント (ブラウザ) の両方で使用されるインポートを定義します。
- **ブラウザ互換性:** ブラウザで使用するために、`npm:` 指定子を自動的に `https://esm.sh/` URLに変換します。

---

## 統合フロー

Salviaはフレームワークに依存しないように設計されています。

### Rails統合

Salviaは以下の機能を自動的に行うRailtieを提供します：
1.  開発環境で `Salvia::DevServer` をマウント。
2.  `Rails.root` に基づいてエンジンを設定。
3.  Action Controllerにヘルパーを注入。

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.all
    # Renders salvia/app/pages/posts/Index.tsx
    render html: ssr("posts/Index", { posts: @posts })
  end
end
```


## 内部モジュール構造 (クリーンアーキテクチャ)

Salviaのコードベースは、保守性と関心の分離を確保するために整理されています：

- **`Salvia::Core`**: コアロジックと設定 (`configuration.rb`, `import_map.rb`, `path_resolver.rb`)。
- **`Salvia::Server`**: サーバーとプロセス管理 (`dev_server.rb`, `sidecar.rb`)。
- **`Salvia::Compiler`**: JITコンパイルロジックとアダプター (`compiler.rb`, `adapters/`)。
- **`Salvia::SSR`**: サーバーサイドレンダリングエンジン (`ssr.rb`, `quickjs.rb`)。
- **`Salvia::Helpers`**: Rails用ビューヘルパー (`helpers.rb`, `island.rb`)。

---

## 設計哲学

1.  **真のHTMLファースト**: サーバーは完全に形成されたHTMLを送信すべきです。JavaScriptはレンダリングではなく、拡張のためにあります。
2.  **Ruby駆動**: 開発者体験はRubyネイティブに感じるべきです。別の `npm run dev` プロセスは不要です。
3.  **Web標準**: 標準Web API (Fetch, ESM, URL) とDeno上に構築されており、プロプライエタリなロックインを回避します。
4.  **ゼロコンフィグ (ほぼ)**: 設定より規約。`deno.json` が依存関係を処理し、ディレクトリ構造が振る舞いを決定します。
