# Sage Framework ⚠️discontinued　🌿

**Sage** は、RubyとDeno (Falcon) 上に構築された、軽量で高性能なフルスタックフレームワークです。

Ruby (Backend) の優雅さと、Deno (Frontend/SSR) のモダンなエコシステムを融合させ、Railsのような開発体験とネイティブなReact/Preactサポートを提供します。

## 特徴

*   **Sage Native Architecture**: Rubyは「土管 (Dumb Pipe)」として振る舞い、レンダリングとアセット配信をDenoサイドカープロセスに委譲します。
*   **Zero API**: ActiveRecordオブジェクトを直接 `ctx.render` に渡すだけ。シリアライザやAPIエンドポイントは不要です。
*   **Deno SSR**: 設定不要でPreactコンポーネントをサーバーサイドレンダリングします。
*   **Islands Architecture**: `"use hydration";` を付けるだけで、特定の部分だけをクライアントサイドでインタラクティブにできます。
*   **オンデマンドコンパイル**: 組み込みの **esbuild** が `.tsx` ファイルをオンザフライでコンパイルします。WebpackやViteは不要です。
*   **npmサポート**: `deno.json` を通じて、あらゆるnpmパッケージをフロントエンドで使用できます。

## ドキュメント

詳細なドキュメントは [DOCUMENTATION.md](DOCUMENTATION.md) を参照してください。

## クイックスタート

### インストール

```bash
gem install sage
```

### プロジェクトの作成

```bash
sage new my_app
cd my_app
bundle install
```

### 開発サーバーの起動

```bash
bundle exec sage dev
```

http://localhost:3000 にアクセスすると、Sageアプリケーションが動作していることを確認できます。

## ディレクトリ構造

```
packages/
└── sage/    # Sageフレームワーク本体
demo_app/    # デモアプリケーション
```
