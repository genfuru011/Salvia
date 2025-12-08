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

### 3. Routing Enhancement

`Salvia::Router` を強化し、ネストしたリソースと名前付きルートをサポートしました。

```ruby
resources :posts do
  resources :comments
end
```

これにより、以下のパスとヘルパーが生成されます：
- `/posts/:post_id/comments` -> `post_comments_path(post_id)`
- `/posts/:post_id/comments/:id` -> `post_comment_path(post_id, id)`

`Mustermann` のパターンマッチングと `ActiveSupport` の単数形化ロジックを組み合わせて実現しています。

---

## v0.5.0: Rich UI & Advanced Features

### 1. HTMX Helpers

`Salvia::Helpers::Htmx` モジュールを追加し、HTMX 属性を簡単に扱えるようにしました。

```ruby
# Link
<%= htmx_link_to "Delete", post_path(@post), 
      method: :delete, 
      target: "#post-#{@post.id}", 
      confirm: "Are you sure?" %>

# Form
<%= htmx_form post_path(@post), method: :put, target: "#result" %>
  <input type="text" name="title">
  <button type="submit">Save</button>
<%= form_close %>
```

また、`htmx_trigger` や `htmx_request?` もこのモジュールに移動し、コントローラーとビューの両方で利用可能にしました。

### 2. View Components

再利用可能な UI コンポーネントを作成するための `Salvia::Component` クラスと `component` ヘルパーを追加しました。

**コンポーネント定義:** `app/components/user_card_component.rb`
```ruby
class UserCardComponent < Salvia::Component
  def initialize(user:)
    @user = user
  end
end
```

**テンプレート:** `app/components/user_card_component.html.erb`
```erb
<div class="card">
  <h2><%= user.name %></h2>
</div>
```

**使用方法:**
```erb
<%= component "user_card", user: @user %>
```

### 3. Salvia Islands (v0.6.0)

Node.js 不要で Island Architecture を実現する機能を実装しました。

**Import Maps:** `config/importmap.rb`
```ruby
Salvia.importmap.draw do
  pin "preact", to: "https://esm.sh/preact@10.19.3"
  pin "Counter", to: "/islands/Counter.js"
end
```

**Island Component:** `app/islands/Counter.js`
```javascript
import { useState } from 'preact/hooks';
import { html } from 'htm/preact';

export function Counter({ initial = 0 }) {
  const [count, setCount] = useState(initial);
  return html`...`;
}
```

**View:**
```erb
<%= island "Counter", initial: 10 %>
```

---

## v0.4.0: Production Ready

### 1. Environment Configuration

`Salvia.load_config` メソッドを追加し、アプリケーション起動時に `config/environments/#{Salvia.env}.rb` を読み込むようにしました。
これにより、環境ごとに異なる設定（ロギング、データベース接続オプションなど）を記述できるようになりました。

### 2. Logging

`Salvia.logger` を導入し、標準の `Logger` クラスを使用するようにしました。
`config/environments/*.rb` で以下のように設定できます：

```ruby
Salvia.configure do |config|
  config.logger = Logger.new("log/production.log")
  config.logger.level = Logger::INFO
end
```

また、`Rack::CommonLogger` にこのロガーを渡すことで、アクセスログも同じ出力先に統合されます。

### 3. Asset Management

本番環境でのキャッシュバスティング（Cache Busting）を実現するために、以下の機能を実装しました：

- **`Salvia::Assets`**: `public/assets/manifest.json` を読み込み、論理パスからハッシュ付きパスへの解決を行います。
- **`assets:precompile`**: `public/assets` 以下のファイルをハッシュ付きでコピーし、マニフェストファイルを生成する CLI コマンド。
- **`asset_path`**: コントローラーとビューで使用できるヘルパー。開発環境ではそのままのパスを、本番環境ではマニフェストに基づいたパスを返します。

### 4. Testing Support

`Salvia::Test::ControllerHelper` を提供し、`rack-test` を利用したコントローラーテストを簡単に書けるようにしました。
`salvia new` で生成されるプロジェクトには、デフォルトで `test/` ディレクトリとサンプルテストが含まれます。

```ruby
class HomeControllerTest < Minitest::Test
  def test_index
    get "/"
    assert last_response.ok?
    assert_includes last_response.body, "Salvia"
  end
end
```

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
