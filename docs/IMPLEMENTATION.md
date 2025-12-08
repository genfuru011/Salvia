# Salvia.rb Implementation Notes

> 実装の詳細と技術的な決定事項の記録

---

## v0.2.0: Zeitwerk Integration & Code Reloading

### 概要

Rails のような「設定不要のオートローディング」と「開発時のコードリロード」を実現するために、[Zeitwerk](https://github.com/fxn/zeitwerk) を導入しました。

### 1. Gem 内部のオートロード

`salvia_rb` gem 自体のコンポーネント読み込みを `require_relative` から Zeitwerk に移行しました。

```ruby
# lib/salvia_rb.rb
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/salvia_rb/version.rb")
loader.inflector.inflect(
  "salvia_rb" => "Salvia",
  "cli" => "CLI"
)
loader.setup
```

これにより、`Salvia::Router` や `Salvia::Controller` などのクラスが、使用されるまで読み込まれなくなります（遅延ロード）。

### 2. アプリケーションのオートロード

生成されるアプリケーション (`salvia new` で作成) も Zeitwerk を使用して `app/` 以下のコードを管理します。

```ruby
# config/environment.rb
loader = Zeitwerk::Loader.new
loader.push_dir(File.join(Salvia.root, "app", "controllers"))
loader.push_dir(File.join(Salvia.root, "app", "models"))

# 開発環境のみリロードを有効化
loader.enable_reloading if Salvia.development?

loader.setup
Salvia.app_loader = loader # リローダーを保持
```

### 3. コードリロードの仕組み

Rack アプリケーションのエントリーポイントで、リクエストごとにリロードをトリガーします。

```ruby
# lib/salvia_rb/application.rb
def call(env)
  # 開発環境かつリローダーが設定されている場合
  if Salvia.development? && Salvia.app_loader
    Salvia.app_loader.reload
  end

  request = Rack::Request.new(env)
  # ...
end
```

Zeitwerk の `reload` メソッドは、ファイルに変更があった場合のみ定数をアンロードして再読み込みするため、効率的です。

### 4. 依存関係の更新 (Rack 3.0 対応)

Rack 3.0 以降の変更に対応するため、以下の gem を依存関係に追加しました：

- `rackup`: `rackup` コマンドが Rack 本体から分離されたため
- `rack-session`: セッション機能が分離されたため
- `mustermann-contrib`: `Mustermann::Rails` などの拡張機能用

### 5. Error Handling

- **Custom Error Pages**: 本番環境では `public/404.html` と `public/500.html` を優先して表示するように変更しました。
- **CLI**: 新規プロジェクト作成時にデフォルトのエラーページを生成します。

---

## v0.3.0: Security & Stability

### 1. Flash Messages

`Salvia::Flash` クラスを実装し、`session[:_flash]` を使用してメッセージを管理します。
`flash[:notice]` は次のリクエストまで、`flash.now[:alert]` は現在のリクエストのみ有効です。

### 2. CSRF Protection

`Rack::Protection` を導入し、以下の攻撃に対する防御を有効化しました：
- `authenticity_token`: CSRF トークンの検証
- `cookie_tossing`: クッキーの競合防止
- `form_token`: フォーム送信時のトークン検証
- `remote_referrer`: リファラー検証
- `session_hijacking`: セッションハイジャック対策

また、HTMX リクエストに対しては、`app.js` で自動的に `X-CSRF-Token` ヘッダーを付与するように設定しています。

---

## v0.1.0: Foundation

### Core Architecture

- **Application**: Rack インターフェース (`call`) を実装。リクエストを Router に渡す。
- **Router**: `Mustermann` を使用したパターンマッチング。`recognize` でコントローラーとアクションを特定。
- **Controller**: `Tilt` + `Erubi` で ERB テンプレートをレンダリング。

### Smart Rendering

HTMX リクエストを検出し、レイアウトの適用を制御します。

```ruby
def determine_layout(layout_option, template)
  return false if layout_option == false
  return false if template.start_with?("_") # パーシャル
  return false if htmx_request?           # HTMX リクエスト
  layout_option || default_layout
end
```

これにより、同じコントローラーアクションで「初回アクセス（フルページ）」と「HTMX リクエスト（部分更新）」の両方に対応できます。

---

*最終更新: 2025-12-08*
