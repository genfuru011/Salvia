# Salvia 🌿

> **Rails View層の未来**

Salviaは、Ruby on RailsのERBを **JSX/TSX** に置き換えるために設計された次世代の **サーバーサイドレンダリング (SSR) エンジン** です。**Islands Architecture** と **True HTML First** の哲学をRailsエコシステムにもたらします。

<img src="https://img.shields.io/gem/v/salvia?style=flat-square&color=ff6347" alt="Gem">

## ビジョン: Sageへの道

Salviaは、将来のMVCフレームワーク **Sage** のためのコアエンジンです。
Sageは完全なスタンドアロンフレームワークになりますが、Salviaは **Ruby on Rails** のView層のドロップイン代替品として *今日から* 利用可能です。

## 特徴

*   🏝️ **Islands Architecture**: インタラクティブなコンポーネント (Preact/React) を必要な場所でのみレンダリングします。静的コンテンツにはJSゼロ。
*   🚀 **True HTML First**: `app/views/**/*.erb` を `app/pages/**/*.tsx` に置き換えます。
*   ⚡ **JIT Compilation**: 開発中のビルドステップはありません。`rails s` を実行するだけです。
*   💎 **Rails Native**: Controller、Route、Modelとシームレスに統合されます。
*   🦕 **Deno Powered**: 超高速なTypeScriptコンパイルとフォーマットにDenoを使用します。

## インストール

RailsアプリケーションのGemfileに以下の行を追加してください:

```ruby
gem 'salvia'
```

そして実行してください:

```bash
$ bundle install
```

## はじめに

### 1. Salviaのインストール

インタラクティブインストーラーを実行して、Railsプロジェクト用にSalviaをセットアップします:

```bash
$ bundle exec salvia install
```

これにより `salvia/` ディレクトリ構造が作成され、**ゼロコンフィグ** セットアップ (Preact + Signals) でアプリが構成されます。

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

### 3. コントローラーでのレンダリング

Railsコントローラーで:

```ruby
class HomeController < ApplicationController
  def index
    # salvia/app/pages/home/Index.tsx をレンダリング
    render html: ssr("home/Index", title: "Hello Salvia")
  end
end
```

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

### 4. Turbo Drive (オプション)

SalviaはTurbo Driveとシームレスに連携し、SPAのようなナビゲーションを実現します。

レイアウトファイル (例: `app/pages/layouts/Main.tsx`) にTurboを追加します:

```tsx
<head>
  {/* ... */}
  <script type="module">
    import * as Turbo from "https://esm.sh/@hotwired/turbo@8.0.0";
    Turbo.start();
  </script>
</head>
```

このアプローチはImport Mapとブラウザネイティブモジュールを活用し、バンドルサイズを小さく保ち、アーキテクチャを透明にします。

## ドキュメント

*   **English**:
    *   [**Wisdom for Salvia**](../en/DESIGN.md): Deep dive into the architecture, directory structure, and "True HTML First" philosophy.
    *   [**Architecture**](../en/ARCHITECTURE.md): Internal design of the gem.
*   **Japanese (日本語)**:
    *   [**Salviaの知恵**](DESIGN.md): アーキテクチャ、ディレクトリ構造、「真のHTMLファースト」哲学についての詳細。
    *   [**アーキテクチャ**](ARCHITECTURE.md): Gemの内部設計。

## フレームワークサポート

Salviaは主に **Ruby on Rails** 向けに設計されており、**Sage** フレームワークへの道を切り開きます。

*   **Ruby on Rails**: ファーストクラスサポート。

## 要件

*   Ruby 3.1+
*   Rails 7.0+ (推奨)
*   Deno (JITコンパイルとツール用)

## ライセンス

このgemは [MIT License](https://opensource.org/licenses/MIT) の下でオープンソースとして利用可能です。
