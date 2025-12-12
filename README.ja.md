# Salvia 🌿

> **Rails View層の未来**

Salviaは、Ruby on RailsのERBを **JSX/TSX** に置き換えるために設計された次世代の **サーバーサイドレンダリング (SSR) エンジン** です。**Islands Architecture** と **True HTML First** の哲学をRailsエコシステムにもたらします。

<img src="https://img.shields.io/gem/v/salvia?style=flat-square&color=ff6347" alt="Gem">

## ビジョン: Sageへの道

Salviaは、将来のフレームワーク **Sage** (Express, Hono, Oakライクな設計) のためのコアエンジンです。
Sageは完全なスタンドアロンフレームワークになりますが、Salviaは **Ruby on Rails** のView層のドロップイン代替品として *今日から* 利用可能です。

## 特徴

*   🏝️ **Islands Architecture**: インタラクティブなコンポーネント (Preact/React) を必要な場所でのみレンダリングします。静的コンテンツにはJSゼロ。
*   🚀 **True HTML First**: `app/views/**/*.erb` を `app/pages/**/*.tsx` に置き換えます。
*   ⚡ **JIT Compilation**: 開発中のビルドステップはありません。`rails s` を実行するだけです。
*   💎 **Rails Native**: Controller、Route、Modelとシームレスに統合されます。
*   🦕 **Deno Powered**: 超高速なTypeScriptコンパイルとフォーマットにDenoを使用します。

## 要件

*   Ruby 3.1+
*   Rails 7.0+ (推奨)
*   **Deno 1.30+** (JITコンパイルとツール用に必須)

## インストール

### 1. Denoのインストール

SalviaはDenoを必要とします。[公式インストールガイド](https://deno.land/#installation)に従ってください。

```bash
# macOS / Linux
$ curl -fsSL https://deno.land/x/install/install.sh | sh
```

### 2. Gemの追加

RailsアプリケーションのGemfileに以下の行を追加してください:

```ruby
gem 'salvia'
```

そして実行してください:

```bash
$ bundle install
```

## はじめに

### 1. Salviaのセットアップ

インタラクティブインストーラーを実行して、Railsプロジェクト用にSalviaをセットアップします:

```bash
$ bundle exec salvia install
```

このコマンドは以下の処理を行います:
1.  `salvia/` ディレクトリ構造の作成。
2.  `deno.json` (依存関係の SSOT) の生成。
3.  **Deno依存関係のキャッシュ** (初回起動の高速化)。
4.  Rails設定の更新 (`Salvia::Helpers` の注入)。

#### ディレクトリ構造

```
salvia/
├── app/
│   ├── components/  # 共有UIコンポーネント (Buttons, Cards)
│   ├── islands/     # インタラクティブコンポーネント (クライアントでハイドレーション)
│   └── pages/       # サーバーコンポーネント (SSRのみ, クライアントへのJSは0kb)
└── deno.json        # 依存関係管理 (Import Map)
```

### 2. ページ (Server Component) の作成

`app/views/home/index.html.erb` を削除し、`salvia/app/pages/home/Index.tsx` を作成します:

```tsx
import { h } from 'preact';

export default function Home({ title }) {
  return (
    <div class="p-10">
      <h1 class="text-3xl font-bold">{title}</h1>
      <p>これはサーバー上でレンダリングされ、クライアントには0kbのJavaScriptが送信されます。</p>
    </div>
  );
}
```

### 3. コントローラーでのレンダリング (API Mode / Full Page SSR)

Railsコントローラーで、`Salvia::SSR.render_page` を使用してコンポーネントを直接レンダリングします。これはERBを完全にバイパスする、推奨される「APIモード」または「Full Page SSR」アプローチです。

```ruby
class HomeController < ApplicationController
  def index
    # salvia/app/pages/home/Index.tsx をレンダリング
    # <!DOCTYPE html> と Import Map を含む完全なHTML文字列を返します
    render html: Salvia::SSR.render_page("home/Index", title: "Hello Salvia").html_safe
  end
end
```

> **注意**: ERBヘルパー `<%= island ... %>` は v0.2.0 で非推奨となりました。「真のHTMLファースト」アーキテクチャのため、コントローラーベースのレンダリングを強く推奨します。

### 4. インタラクティビティの追加 (Islands)

`salvia/app/islands/Counter.tsx` にインタラクティブなコンポーネントを作成します:

```tsx
import { h } from 'preact';
import { useState } from 'preact/hooks';

export default function Counter() {
  const [count, setCount] = useState(0);
  return (
    <button onClick={() => setCount(count + 1)} class="btn">
      Count: {count}
    </button>
  );
}
```

ページで使用します:

```tsx
import Counter from '../../islands/Counter.tsx';

export default function Home() {
  return (
    <div>
      <h1>Interactive Island</h1>
      <Counter />
    </div>
  );
}
```

### 5. Turbo Drive (オプション)

SalviaはTurbo Driveとシームレスに連携し、SPAのようなナビゲーションを実現します。

レイアウトファイル (例: `salvia/app/pages/layouts/Main.tsx`) にTurboを追加します:

```tsx
<head>
  {/* ... */}
  <script type="module">
    import * as Turbo from "@hotwired/turbo";
    Turbo.start();
  </script>
</head>
```

`deno.json` で依存関係を管理しているため、URLを直接書く必要はありません。

## コアコンセプト: Pages vs Islands

「真のHTMLファースト」開発において、関心の分離を理解することは重要です。

| 機能 | **Pages (Server Components)** | **Islands (Client Components)** |
| :--- | :--- | :--- |
| **パス** | `salvia/app/pages/` | `salvia/app/islands/` |
| **環境** | サーバー (Ruby/QuickJS) | クライアント (ブラウザ) |
| **インタラクティブ** | ❌ 静的 HTML | ✅ インタラクティブ (イベントリスナー) |
| **状態 (State)** | ❌ ステートレス | ✅ ステートフル (Signals/Hooks) |
| **ブラウザ API** | ❌ なし (`window`, `document` はモック) | ✅ あり |
| **用途** | レイアウト, 初期データ取得 | フォーム, モーダル, 動的UI |

## ドキュメント

詳細なドキュメントは現在 **英語のみ** で提供されています。

*   [**Wisdom for Salvia**](docs/en/DESIGN.md): アーキテクチャ、ディレクトリ構造、「真のHTMLファースト」哲学についての詳細。
*   [**Reference Guide**](docs/en/REFERENCE.md): 使用方法、API、設定に関する包括的なガイド。
*   [**Architecture**](docs/en/ARCHITECTURE.md): Gemの内部設計。

## フレームワークサポート

Salviaは主に **Ruby on Rails** 向けに設計されており、**Sage** フレームワークへの道を切り開きます。

*   **Ruby on Rails**: ファーストクラスサポート。

## ゼロコンフィグアーキテクチャ

Salvia v0.2.0 は **ゼロコンフィグ** 哲学を採用しています。

*   **`deno.json` が SSOT**: サーバー (SSR) とクライアント (ブラウザ) 両方の依存関係を管理します。
*   **自動 Import Map**: `deno.json` 内の `npm:` 指定子は、ブラウザ用に自動的に `esm.sh` URL に変換されます。
*   **ビルド設定不要**: `build.ts` と `sidecar.ts` は内部で管理されますが、`deno.json` の `salvia.globals` でグローバル変数を拡張できます。

## 本番環境 & CI

本番環境 (Docker, Heroku, Render など) では:

1.  **Deno が必須**: ビルド/ランタイム環境に Deno がインストールされていることを確認してください。
2.  **ビルドステップ**: デプロイ時に `bundle exec salvia build` を実行してください。
    *   Islands のバンドル、Import Map の生成、Tailwind CSS のビルドを行います。
    *   キャッシュバスティング用にハッシュ付きファイル名を生成します。

## ライセンス

このgemは [MIT License](https://opensource.org/licenses/MIT) の下でオープンソースとして利用可能です。
