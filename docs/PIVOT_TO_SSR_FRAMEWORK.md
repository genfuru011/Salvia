# Salvia ピボット計画: MVCからSSRフレームワークへ

## ビジョン
**"Salvia" を「ゼロ設定MVCフレームワーク」から「Ruby Islands Architecture エンジン」へと再定義する。**

RailsやHanamiと競合するのではなく、SalviaはRubyエコシステムにおいて「Islands Architecture」を実装するための標準ツールとなることを目指します。レンダリングエンジン、ビルドシステム、ハイドレーションロジックを提供し、あらゆるRackベースのアプリケーション（Railsを含む）で利用可能にします。

## 戦略

### フェーズ 1: 大解体 (現在のリポジトリ)
現在の `Salvia` コードベースを、その核心的価値である「SSRエンジン」のみに削ぎ落とします。

*   **維持・強化**:
    *   `Salvia::SSR::QuickJS`: コアとなるレンダリングエンジン。
    *   `Salvia::Helpers`: `island` ヘルパーとコンポーネントのマウント機能。
    *   `bin/build_ssr.ts` & `islands.js`: ビルドおよびハイドレーションシステム。
    *   `Salvia::CLI`: `build`, `watch`, `install` コマンドのみに集中。
*   **削除 (またはアーカイブへ移動)**:
    *   `Salvia::Router`: ルーティングロジック。
    *   `Salvia::Controller`: アクション処理。
    *   `Salvia::Database`: ActiveRecord統合。
    *   `Salvia::Application`: モノリシックなアプリ構造。

### フェーズ 2: フレームワーク統合
Salviaを既存のフレームワークに簡単にインストールできるようにします。

*   **Rack統合**: 開発環境でのアセット配信とSSRを処理するミドルウェアを提供。
*   **Railsエンジン**: `Salvia::Railtie` を作成し、Railsのビューヘルパーやアセットパイプラインに自動的にフック。
*   **スタンドアロンモード**: シンプルなRackアプリ（Sinatra, Roda）でも利用可能に。

### フェーズ 3: MVCの再構築 (将来)
Salvia（SSRエンジン）が安定し普及した後に、その**上に**新しいMVCフレームワークを構築します。

*   **プロジェクト名案**: `Sage` (Salviaはセージの一種)。
*   **コンセプト**: Salviaをデフォルトのビューエンジンとして採用した軽量MVCフレームワーク。
*   **依存関係**: `gem 'salvia'` (SSRエンジン)。

## 技術的変更

### Gem構造
`salvia_rb` gemは以下のようになります：

```ruby
module Salvia
  # Core SSR Engine
  autoload :Engine, 'salvia/engine'
  autoload :Renderer, 'salvia/renderer'
  
  # Framework Integrations
  autoload :Rails, 'salvia/rails'
  autoload :Sinatra, 'salvia/sinatra'
  
  # Configuration
  def self.configure; end
end
```

### 使用例 (Railsの場合)

```ruby
# config/initializers/salvia.rb
Salvia.configure do |config|
  config.islands_dir = "app/javascript/islands"
end

# app/views/home/index.html.erb
<%= island "Counter", count: 10 %>
```

## アクションアイテム

1.  **アーカイブ**: 現在の状態を保存するために `legacy-mvc` ブランチを作成。
2.  **削除**: `main` ブランチから Router, Controller, Database のコードを削除。
3.  **リファクタリング**: SSRロジックをライブラリのトップレベルに移動。
4.  **リネーム**: `gemspec` の説明と `README.md` を更新。
5.  **リリース**: 新しいSSRフレームワークとして `v0.2.0` (または `v1.0.0`) を公開。
