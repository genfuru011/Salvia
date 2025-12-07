# Simple MVC Ruby Fullstack Framework

# **フレームワークのコンセプト**

> HTMX × Tailwind × ActiveRecord を前提にした
> 

> 小さくて理解しやすい Ruby MVC フレームワーク
> 
- サーバレンダリング（HTMLベース）
- 画面更新は HTMX の部分更新が基本
- 見た目は Tailwind（ローカルビルド済みCSS）
- モデルは ActiveRecord（Railsとほぼ同じ感覚）
- DB は「ActiveRecord が繋がるなら何でもOK」（付け替えレイヤーは作らない）

### Salvia.rb: "Blue Wisdom"

名前が決まれば、次は「色」と「言葉」をプロジェクトの顔にしましょう。

- **Gem Name:** `salvia_rb`
- **Module Name:** `Salvia` (コード内ではシンプルに `Salvia.config` などのように書けるように設計するのが美しくておすすめです)
- **Theme Color:** **ブルーサルビアの色 (#4B0082 〜 #6A5ACD)**
    - 深い青紫色。知的で落ち着いた、大人のRubyist向けの色合いです。
- **Tagline (キャッチコピー案):**
    - *"Wisdom for Rubyists."* (Rubyistに知恵を)
    - *"Simple, like a flower. Solid, like a gem."* (花のようにシンプル、石のように堅牢)
    - *“*Salvia.rb*: a tiny Ruby MVC for wise and clear web apps.”*
    - *“From boilerplate to blueprints:* Salvia.rb *helps you express the truth of your domain with minimal code.”*
    - *“Write less, see more.* Salvia.rb *brings wisdom and clarity to your Ruby stack.”*

---

## **全体構成イメージ**

### **技術スタック**

- **サーバ**
    - Ruby + Rack
    - 自作 Router（Railsっぽい DSL）
    - Controller 基底クラス（Myfw::Controller）
    - View: ERB + レイアウト + パーシャル
    - Model: ApplicationRecord < ActiveRecord::Base
- **フロント**
    - HTMX … /assets/javascripts/htmx.min.js を読み込む
    - Tailwind … CLIでビルドした /assets/stylesheets/tailwind.css
    - 必要なら app.js にちょっとだけ自前JS
- **DB**
    - config/database.yml を ActiveRecord でそのまま読む
    - dev/test は SQLite、prod は Neon/RDSなどユーザーが設定

---

### **ディレクトリ構成（**

### **myfw new app_name**

### **で生成される想定）**

```yaml
myapp/
  app/
    controllers/
      application_controller.rb
      home_controller.rb
    models/
      application_record.rb
      todo.rb
    views/
      layouts/
        application.html.erb
      home/
        index.html.erb
        _list.html.erb
      components/
        _todo.html.erb
  app/assets/
    stylesheets/
      application.tailwind.css   # @tailwind base/components/utilities
  config/
    routes.rb
    database.yml
    environment.rb
  db/
    migrate/
    schema.rb
  public/
    assets/
      javascripts/
        htmx.min.js
        app.js
      stylesheets/
        tailwind.css             # ビルド後
  Gemfile
  Rakefile
```

---

## **MVC の流れ**

### **Router（Railsっぽい）**

```ruby
# config/routes.rb
Myfw::Router.draw do
  root to: "home#index"

  resources :todos, only: [:index, :create, :destroy]
end
```

### **Controller**

```ruby
class ApplicationController < Myfw::Controller
  # 共通処理を書く場所
end

class HomeController < ApplicationController
  def index
    @todos = Todo.order(created_at: :desc)
    render_view "home/index"   # HTMXならpartial、通常ならlayout付き
  end

  def create
    Todo.create!(title: params["title"])
    @todos = Todo.order(created_at: :desc)
    render_partial "home/list", todos: @todos
  end
end
```

- render, render_partial, render_view
- params, session, redirect_to
- htmx_request?（HX-Requestヘッダ見る）

### **View（HTMX + Tailwind 前提）**

```html
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title><%= @title || "MyFW App" %></title>

  <link rel="stylesheet" href="/assets/stylesheets/tailwind.css" />

  <script src="/assets/javascripts/htmx.min.js" defer></script>
  <script type="module" src="/assets/javascripts/app.js"></script>
</head>
<body class="min-h-screen bg-slate-50">
  <%= yield %>
</body>
</html>
```

```html
<!-- app/views/home/index.html.erb -->
<div class="max-w-xl mx-auto mt-8 space-y-4">
  <form
    hx-post="/todos"
    hx-target="#todo-list"
    hx-swap="innerHTML"
    class="flex gap-2"
  >
    <input
      name="title"
      class="flex-1 border px-2 py-1 rounded"
      placeholder="やること…"
    />
    <button class="px-3 py-1 rounded bg-blue-500 text-white">
      追加
    </button>
  </form>

  <div id="todo-list">
    <%= render "home/list", todos: @todos %>
  </div>
</div>
```

```html
<!-- app/views/home/_list.html.erb -->
<ul class="space-y-1">
  <% todos.each do |todo| %>
    <li class="border rounded px-2 py-1 flex justify-between">
      <span><%= todo.title %></span>
    </li>
  <% end %>
</ul>
```

### **Model（ActiveRecord）**

```ruby
# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end

# app/models/todo.rb
class Todo < ApplicationRecord
  validates :title, presence: true
end
```

---

## **DB・assets の扱い**

### **DB（ActiveRecord に丸投げ）**

config/database.yml 例：

```yaml
default: &default
  adapter: sqlite3
  pool: 5
  timeout: 5000

development:
  <<: *default
  database: db/development.sqlite3

test:
  <<: *default
  database: db/test.sqlite3

production:
  adapter: postgresql
  url: <%= ENV["DATABASE_URL"] %>   # Neonとかをここに
```

Myfw::Database.setup!(env) がこれを読んで：

```ruby
ActiveRecord::Base.establish_connection(env_config)
```

するだけ。

### **HTMX / Tailwind を assets に置く**

- HTMX：
    - public/assets/javascripts/htmx.min.js を myfw new 時に配置
    - <script src="/assets/javascripts/htmx.min.js" defer></script>
- Tailwind：
    - 元CSS: app/assets/stylesheets/application.tailwind.css
    - ビルド後: public/assets/stylesheets/tailwind.css
    - レイアウトで <link rel="stylesheet" href="/assets/stylesheets/tailwind.css" />

Tailwind ビルド用に CLI ラッパを用意：

```
myfw css:build   # 本番ビルド
myfw css:watch   # 開発中ウォッチ
```

---

## **CLI / 開発フロー**

用意したいコマンド：

- myfw new app_name
- myfw server
- myfw db:create
- myfw db:migrate
- myfw db:setup
- myfw css:build
- myfw css:watch

開発ループ：

```
myfw new todo_app
cd todo_app
bundle install
myfw db:setup
myfw css:build
myfw server
```

---

こんな感じで、

- コア前提：**HTMX / Tailwind / ActiveRecord**
- HTMX・Tailwindは **ファイルとして assets 管理**
- DB は **ActiveRecord が繋がるなら何でもOK（付け替えレイヤーなし）**

という設計にまとまった感じ🙌

## Gemini Review

## Review 1

このコンセプト、**最高にモダンで、かつ「Rubyらしい」**です。

Railsが「おまかせコースのフルコース料理」だとすれば、Salviaは「**素材の味（ActiveRecord/HTMX）を最大限に活かした、とびきり美味しいワンプレートランチ**」のようです。

「HTMX + Tailwind + ActiveRecord」という組み合わせは、現在、**個人の開発者や少人数のチームが最速でプロダクトを作るための「勝ちパターン（The Golden Stack）」**になりつつあります。これをRubyで、しかも「オレオレフレームワーク」ではなく「美しいGem」として提供するのは、非常に価値があります。

いただいた設計をもとに、実装の解像度を少し上げたフィードバックと、**「Salviaらしさ（＝賢いシンプルさ）」**を実装するための具体的な提案をまとめました。

---

### 🎨 Salvia.rb デザインフィードバック

コンセプト全体として、「**余計な抽象化はせず、巨人の肩（ActiveRecord/HTMX/Tailwind）に素直に乗る**」という姿勢が一貫しており、迷いがありません。

特に素晴らしい点：

1. **DB抽象化なし:** 「どうせActiveRecord使うんでしょ？」と割り切ったことで、開発者はRailsの知識（バリデーションやクエリ）を100%再利用できます。
2. **JSビルドなし:** `app.js` は ESM (`type="module"`) で読み込み、TailwindはCLIでCSSを作るだけ。WebpackやViteの複雑さから解放されます。
3. **HTMXファースト:** 「JSON APIを作ってSPAで…」という迷いを断ち切り、「HTMLを返す」ことに特化しています。

---

### 🧠 "Blue Wisdom"（賢い実装）への提案

Salviaの「知性」を表現するために、Controllerの挙動をもう少しだけ「気が利く（Smart）」形にすると、さらにコードが美しくなりそうです。

### 1. Smart Rendering (賢いレンダリング)

Controllerで render_view と render_partial を使い分けるのは少し冗長かもしれません。

Salviaが「HTMXリクエストかどうか」を自動判断し、開発者は意識せずに済むようにするのはいかがでしょう？

**Before:**

```ruby
def create# ...
  render_partial "home/list", todos: @todos # HTMX用
end
```

**After (Salvia Way):**

```ruby
def create# ...
  # Salviaが「あ、これHTMXリクエストだね。じゃあLayoutは外してPartialだけ返すよ」と判断
  render "home/list", todos: @todos 
end
```

**実装イメージ（Myfw::Controller）:**

```ruby
def render(view_path, locals = {})# HTMXヘッダがあればレイアウトなし、なければレイアウトあり
  layout = htmx_request? ? nil : "layouts/application"
  
  body = render_erb(view_path, locals)
  
  if layout
    render_erb(layout) { body }
  else
    body
  end
end

def htmx_request?
  request.env['HTTP_HX_REQUEST'] == 'true'
end
```

これで、「**書くコードは減り、意図は明確になる（＝Simple & Wise）**」を実現できます。

### 2. Tailwind CLI の取り扱い (脱Node.js)

「小さくて理解しやすい」を守るため、ユーザーに npm install をさせない構成が理想です。

Ruby界隈には tailwindcss-ruby という、TailwindのスタンドアロンバイナリをラップしたGemがあります。

これを `Salvia` の依存（またはデフォルトGem）に含めると：

- Node.js不要
- `bundle install` だけで環境構築完了
- `Salvia::CLI` から `Tailwindcss::Ruby.compile` を呼ぶだけでビルド可能

これこそ「**Solid, like a gem**」な構成になります。

---

### 🛠 ディレクトリ構成の微調整案

提示された構成は完璧ですが、1点だけ。HTMX主体のアプリでは「**Partial（部分テンプレート）**」が主役になります。Railsのように `_list.html.erb` とアンダースコアを付ける慣習は守りつつ、Viewの見通しを良くしたいところです。

```yaml
app/views/
  components/    <-- ボタンやカードなど、汎用的なUI部品
    _button.html.erb
    _card.html.erb
  home/
    index.html.erb
    _list.html.erb
```

Salviaのヘルパーとして `<%= component "button", label: "保存" %>` のようなショートカットがあると、Tailwindのクラス記述量が多い問題（HTMLが汚くなる問題）を、Partialへの切り出しで解決しやすくなります。

---

### Phase 1: The Seed（種まき）

- **Gem作成:** `bundle gem salvia_rb`
- **Rack統合:** `Salvia::Application` クラスを作り、`config.ru` で `run Salvia::Application` できるようにする。
- **Router実装:** 単純な `Hash` ベースか、`Pattern Matching` を使ったルーティング。
- **ActiveRecord接続:** `database.yml` を読んで接続するだけの機能。

### Phase 2: The Sprout（発芽） - 今回のコア

- **Controller:** `render` メソッドの実装（ERBの読み込み）。
- **Generator:** `salvia new` コマンド（Thorを使用）。
    - ここで `public/assets/htmx.min.js` などをコピーしてあげる。
- **Watcher:** `listen` gemなどを使って、ファイル変更検知 → Tailwindビルド → 再起動の流れを作る。

### Phase 3: The Bloom（開花）

- **HTMX Helpers:** `<%= htmx_link_to ... %>` のような便利メソッド。
- **Error Handling:** 開発中のきれいなエラー画面（BetterErrorsみたいなもの）。

---

### 📝 今すぐ使える `salvia_rb` のスケルトンコード

イメージを固めるために、コアとなる部分のコードを書き下してみました。

```ruby
# lib/salvia/application.rb
require "rack"
require "active_record"

module Salviaclass Applicationdef call(env)
      request = Rack::Request.new(env)
      response = Rack::Response.new
      
      # 1. ルーティング (超簡易版)
      # 実際は Router クラスに委譲する
      controller_class, action = router.recognize(request)
      
      if controller_class
        # 2. コントローラー実行
        controller = controller_class.new(request, response)
        controller.process(action)
      else
        response.status = 404
        response.write "Not Found (Salvia)"
      end

      response.finish
    end
    
    def router@router ||= Salvia::Router.new
    end
  end
end

# lib/salvia/controller.rb
module Salviaclass Controllerattr_reader :request, :response, :params

    def initialize(request, response)@request = request
      @response = response
      @params = request.params
    end

    def process(action_name)
      send(action_name)
    end

    def render(view_path, locals = {})# ここに "Smart Rendering" ロジックを入れる
      # HTMXなら layout なし、通常なら layout あり
      view_content = render_erb(view_path, locals)
      
      if htmx_request?
        response.write(view_content)
      else
        layout_content = render_erb("layouts/application") { view_content }
        response.write(layout_content)
      end
    end

    private

    def htmx_request?
      request.env['HTTP_HX_REQUEST'] == 'true'
    end

    # ERBレンダリングの簡易実装
    def render_erb(path, locals = {}, &block)# ... (TiltやERBを直接使う)
    end
  end
end
```

> この「賢いController」と「ActiveRecord」さえあれば、あとはユーザーが自由に書くだけです。
> 

### Review 2

一言で言うと、**「現代のRubyistが『実は一番欲しかった』と思える、現実的かつ理想的な構成」**です。

既存のRailsは「全部入り」で重厚になりすぎ、Sinatraは「手作り」すぎてActiveRecordやモダンフロントエンドの統合に手間がかかる。その**ミッシングリンク（隙間）**を、**HTMX × Tailwind × ActiveRecord** という「勝利の方程式」で埋める設計は、非常に勝算が高いと感じます。

以下に、設計の**強み（Good）**と、実装に向けた**強化ポイント（More Wisdom）**を評価・フィードバックします。

---

### 🟢 1. 設計の強み (Evaluation: Excellent)

1. **「迷わせない」技術スタック (The Golden Stack)**
    - **評価:** ⭐⭐⭐⭐⭐
    - **理由:** 「DBは何でもいいけどActiveRecord」「CSSはTailwind一択」「JSはHTMX」と決め打ちしているのが最大の強みです。設定ファイル（Configuration）よりも**規約（Convention）**を重視しており、ユーザーは「何を使うか」ではなく「何を作るか」に集中できます。
2. **Smart Rendering (HTMX First)**
    - **評価:** ⭐⭐⭐⭐⭐
    - **理由:** `render` メソッド一つで、通常アクセスならHTML全体を、HTMXリクエストなら部分HTML（Partial）を自動で返す設計は、DX（開発者体験）を劇的に向上させます。これこそがSalviaを使う最大の動機になります。
3. **No Node.js (脱ビルド地獄)**
    - **評価:** ⭐⭐⭐⭐
    - **理由:** フロントエンドの複雑さを排除し、Rubyのエコシステムだけで完結させる姿勢が素晴らしいです。`tailwindcss-ruby` などを活用すれば、`npm install` すら不要な世界が作れます。

---

### 🔵 2. アーキテクチャ図解

Salviaの内部でどのような処理が行われるか、リクエストフローを整理しました。

**図解のポイント:**

1. **Router:** URLを解析し、Controllerを特定。
2. **Controller:** ActiveRecordでデータを取得。
3. **Smart Renderer:** `HX-Request` ヘッダを見て、Layoutを使うかどうかを自動分岐。
4. **Response:** 必要なHTML断片だけを高速に返す。

---

### 🟣 3. 実装に向けた強化案 (Add Wisdom)

設計をより「堅牢（Solid）」で「賢い（Wise）」ものにするための具体的な提案です。

### A. ルーティングのバックエンドには `Mustermann` を推奨

「RailsっぽいDSL」を自作するのは素晴らしいですが、URLパターンの解析（`match '/users/:id'` など）をゼロから正規表現で実装するのはバグの温床になりがちです。

- **提案:** Sinatraも採用している **`mustermann`** というGemを内部エンジンとして使う。
- **メリット:** 高速で、Railsライクなパターンマッチングが簡単に実装できます。DSL（`draw do ... end`）の皮だけ被せて、中身はMustermannに任せると安定します。

### B. 開発時の「爆速リロード」には `Zeitwerk` を

「小さくて理解しやすい」とはいえ、コードを変えるたびにサーバー再起動が必要だと開発体験が悪すぎます。

- **提案:** Rails 6以降の標準ローダーである **`zeitwerk`** を標準採用する。
- **実装:**
    
    ```ruby
    # config/environment.rb
    loader = Zeitwerk::Loader.new
    loader.push_dir("app/controllers")
    loader.push_dir("app/models")
    loader.enable_reloading # 開発環境のみ
    loader.setup
    ```
    
    これだけで、ファイル変更即反映の快適な環境が作れます。
    

### C. View Component の導入 (Tailwind対策)

TailwindはHTMLがクラス名で汚れがちです。RailsのPartialだけだと引数渡しが少し面倒です。

- **提案:** 超軽量なコンポーネントクラス、あるいはヘルパーメソッドを標準装備する。
    
    ```ruby
    # app/views/components/button.rb (イメージ)
    def ui_button(text, type: :primary)
      classes = type == :primary ? "bg-blue-500 text-white" : "bg-gray-200"
      tag.button text, class: "px-4 py-2 rounded #{classes}"
    end
    ```
    
    Salviaは「HTMLをきれいに書くための知恵」も提供すべきです。
    

### D. セキュリティ (CSRF)

HTMXはデフォルトで非破壊的メソッド（POST, PUT, DELETE）を送るため、CSRF対策が必須です。

- **提案:** `Rack::Protection` (sinatrarb/rack-protection) をデフォルトのミドルウェアスタックに入れる。
- **HTMX対応:** `<meta name="csrf-token">` をLayoutに出力し、`htmx.min.js` が自動でヘッダに送るようにする記述をデフォルトのJSに含めておく。

---

> 🏁 総合評価：GOサイン
**この設計は、今すぐ作り始める価値があります。**
特に「Railsはオーバースペックだが、Sinatraでは骨組みを作るのが面倒」と感じている層（今のRubyistの多く）に深く刺さるはずです。
> 

## Review 3

Salvia.rb の CLI ツール（salvia コマンド）の実装案です。

Ruby で CLI ツールを作るなら、Rails や Bundler も採用している Thor というライブラリを使うのが最も標準的で「賢い」選択です。

以下に、`salvia new` でアプリの雛形を生成し、`salvia server` で起動するまでの実装スケルトンを示します。

### 📦 前提: Gemspec の依存関係

まず、Salvia 自身の `salvia_rb.gemspec` に以下を追加します。

```ruby
# salvia_rb.gemspec
spec.add_dependency "thor"
spec.add_dependency "rack"
spec.add_dependency "puma"
spec.add_dependency "zeitwerk"
spec.add_dependency "activerecord"
spec.add_dependency "sqlite3" # デフォルトDBとして
spec.add_dependency "tailwindcss-ruby" # CSS用
```

---

### 🛠 CLI の実装 (lib/salvia/cli.rb)

このクラスが `salvia` コマンドの実体です。

```ruby
require "thor"
require "fileutils"

module Salviaclass CLI < Thor
    include Thor::Actions

    # テンプレートファイルの置き場（Gem内のパス）
    def self.source_root
      File.dirname(__FILE__) + "/templates"
    end

    desc "new APP_NAME", "新しい Salvia アプリケーションを作成します"
    def new(app_name)@app_name = app_name
      @app_class_name = app_name.split("_").map(&:capitalize).join

      say "🌱 Creating new Salvia app: #{@app_name}...", :green

      # 1. ディレクトリ作成
      empty_directory app_name
      
      # 2. 基本構造のコピー (app/, config/, db/, public/ 等)
      directory "structure", app_name

      # 3. 動的ファイルの生成 (ERBテンプレートを使用)
      template "Gemfile.tt", "#{app_name}/Gemfile"
      template "config.ru.tt", "#{app_name}/config.ru"
      template "Rakefile.tt", "#{app_name}/Rakefile"
      template "database.yml.tt", "#{app_name}/config/database.yml"

      # 4. HTMX のダウンロード (CDNから取得して配置、またはGemに同梱しておく)
      get "https://unpkg.com/htmx.org@1.9.10", "#{app_name}/public/assets/javascripts/htmx.min.js"

      # 5. 初期セットアップ
      inside app_name do
        run "bundle install"
        run "bundle exec salvia css:build" # 初回CSSビルド
      end

      say "💎 #{@app_name} is ready! Run `cd #{@app_name} && salvia server` to start.", :blue
    end

    desc "server", "サーバーを起動します (alias: s)"
    map "s" => "server"
    def server# Rackup コマンドを叩くだけ
      # ポート指定などのオプションもここで処理可能
      say "🚀 Starting Salvia server...", :green
      exec "bundle exec rackup -p 9292"
    end

    desc "console", "コンソールを起動します (alias: c)"
    map "c" => "console"
    def consolerequire "irb"
      require "./config/environment" # アプリのロード処理
      IRB.start
    end

    # Tailwind 関連のラッパー
    desc "css:build", "Tailwind CSS をビルドします"
    def css_build
      system "bundle exec tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./public/assets/stylesheets/tailwind.css --minify"
    end

    desc "css:watch", "Tailwind CSS の変更を監視します"
    def css_watch
      system "bundle exec tailwindcss -i ./app/assets/stylesheets/application.tailwind.css -o ./public/assets/stylesheets/tailwind.css --watch"
    end

    # DB関連は Rake タスクへ委譲するのが一般的
    desc "db:migrate", "データベースをマイグレートします"
    def db_migrate
      system "bundle exec rake db:migrate"
    end
  end
end
```

---

### 📄 テンプレートファイル例 (lib/salvia/templates/)

`salvia new` で生成されるファイルの中身です。

**1. Gemfile.tt**

```ruby
source "https://rubygems.org"

gem "salvia"
gem "puma"
gem "sqlite3"

group :development do
  gem "debug"
end
```

**2. config.ru.tt**

```ruby
require_relative "config/environment"

use Rack::Static, urls: ["/assets"], root: "public"
# ここに Rack::Protection などを挟む

run Salvia::Application.new
```

**3. Rakefile.tt**

```ruby
require_relative "config/environment"
require "active_record/rake"

# ActiveRecord 用のタスクをロード
include ActiveRecord::Tasks
DatabaseTasks.root = File.dirname(__FILE__)
DatabaseTasks.db_dir = File.join(File.dirname(__FILE__), 'db')
DatabaseTasks.migrations_paths = [File.join(File.dirname(__FILE__), 'db', 'migrate')]
DatabaseTasks.env = ENV['RACK_ENV'] || 'development'
DatabaseTasks.database_configuration = YAML.load_file('config/database.yml')

task :environment do
  require_relative "config/environment"
end
```

---

### 🔌 実行ファイルのセットアップ (bin/salvia)

最後に、この CLI クラスをターミナルから叩けるようにします。

**bin/salvia**

```ruby
#!/usr/bin/env ruby
require "salvia/cli"

# CLI クラスのエントリーポイントを実行
Salvia::CLI.start(ARGV)
```

これを `salvia_rb.gemspec` に登録します。

```ruby
spec.bindir        = "bin"
spec.executables   = ["salvia"]
```

### 💡 この CLI 設計のポイント

1. **シンプルさの維持:**
    - 複雑なロジックは書かず、基本的には `bundle exec ...` や `rake ...` へのエイリアスとして機能させます。
2. **Tailwind の統合:**
    - `css:build` コマンドを用意することで、ユーザーが `npx tailwindcss ...` という長いコマンドを覚える必要をなくしました。
3. **HTMX の自動配置:**
    - `new` した瞬間に `public/assets` に `htmx.min.js` が置かれるため、インターネットがない環境でも開発を始められます（または CDN 版のリンクを貼るだけでも OK ですが、ローカルにあると安心感があります）。

これで `gem install salvia` して `salvia new myapp` すれば、すぐに開発が始められる状態になります！

## Review 4

Salvia.rb（`salvia_rb`）の構想に基づき、パフォーマンス、スケーラビリティ、そして開発難易度を客観的に評価・予測します。

結論から言うと、**「中規模までのCRUDアプリや社内ツール」においては、Rails + React構成よりも圧倒的に高性能かつ高コスパ**ですが、**「超巨大SNSや高度な編集ツール」には向かない**という明確な特性があります。

---

### 1. 🏎 パフォーマンスの想定

Salviaは「**Railsの重さを削ぎ落とし、Sinatraの軽さにActiveRecordのパワーを足した**」位置付けになります。

| **項目** | **想定パフォーマンス** | **解説** |
| --- | --- | --- |
| **レスポンス速度 (TTFB)** | **非常に高速** | RailsのActionDispatchや巨大なMiddlewareスタックを通らないため、Ruby層の処理時間はRailsの**1/2〜1/5**程度に収まる想定です。 |
| **メモリ消費量** | **軽量 (〜100MB)** | 起動時に読み込むGem数が少ないため、低スペックなコンテナ（AWS Fargateの最小構成やRenderの無料枠）でもサクサク動きます。 |
| **体感速度 (UX)** | **爆速** | これがSalviaの真骨頂です。HTMXによる部分更新は、SPA（React）の初期ロード（巨大JSのDLと解析）がないため、**ユーザーは「クリックした瞬間に画面が変わる」**ように感じます。 |
| **ボトルネック** | **DB依存** | Rubyフレームワーク部分が薄いため、遅延の9割は「DBクエリ（ActiveRecord）」に依存します。N+1問題への対策はRails同様に必須です。 |

**比較イメージ:**

- **Rails:** 重装備の戦車（何でもできるが、動き出しが重い）
- **Sinatra:** 自転車（軽いが、荷物を積むとふらつく）
- **Salvia:** **スポーツカー**（必要な装備だけで、舗装路＝Web標準に特化して走る）

---

### 2. 📈 スケーラビリティ

「ユーザー数が増えた時」と「機能が増えた時」で評価が分かれます。

### A. インフラのスケーラビリティ（ユーザー増への対応）

- **評価:** 🟢 **非常に高い**
- **理由:**
    - Salvia自体はステートレス（状態を持たない）な設計なので、サーバー台数を増やせば（横に並べれば）いくらでもリクエストをさばけます。
    - DBはActiveRecordなので、Railsで使われる「リードレプリカ」「シャーディング」などの知見がそのまま使えます。

### B. アプリケーションのスケーラビリティ（複雑さへの対応）

- **評価:** 🟡 **中程度（注意が必要）**
- **「HTMXの天井」:**
    - ブログ、ECサイト、管理画面、SNSのタイムライン程度なら余裕でスケールします。
    - しかし、GoogleスプレッドシートやFigmaのような「複雑な状態管理が必要なUI」を作ろうとすると、HTMLの中にロジックが埋め込まれすぎてメンテナンス不能になります。
    - **解決策:** 「ここだけReactを使う」というハイブリッド構成を許容するかどうかが鍵になります。

---

### 3. 🛠 開発難易度

これは「フレームワークを作る難易度」と「フレームワークを使う難易度」の2つの視点があります。

### A. Salviaを作る難易度（フレームワーク開発者視点）

- **難易度:** **Low 〜 Medium**
- **理由:**
    - ゼロから発明するものが少ないためです。
    - **Rack:** HTTP通信の土台
    - **Mustermann:** ルーティング
    - **Tilt/ERB:** テンプレートエンジン
    - **ActiveRecord:** DB操作
    - これらを「センス良く接着する」のが主な作業です。コード量は数千行で収まり、個人でもメンテナンス可能です。

### B. Salviaを使う難易度（アプリ開発者視点）

- **難易度:** **Very Low (極めて簡単)**
- **学習コスト:**
    - **JavaScript (React/Vue) の知識が不要**なのが最大のメリットです。
    - HTMLタグに `hx-post="/update"` と書くだけで非同期通信ができるため、バックエンドエンジニアにとっては「天国」のような環境です。
    - Rails特有の「魔術（暗黙の了解）」も最小限にするため、コードの流れが追いやすいです。

---

### 📊 総合評価マトリクス

| **フレームワーク** | **向いているPJ** | **向いていないPJ** | **開発スピード** |
| --- | --- | --- | --- |
| **Rails** | 全部入りが必要な大規模開発 | マイクロサービス、超シンプルなAPI | 遅 (設定・学習が多い) → 速 |
| **Sinatra** | APIサーバー、極小ツール | 画面があるWebアプリ（構造化が面倒） | 速 (書き始め) → 遅 (規模拡大時) |
| **Salvia** | **管理画面、社内ツール、中規模B2B** | **高度なインタラクティブUI (ゲーム等)** | **爆速 (初速〜中盤までずっと速い)** |

### 💡 Salviaの戦略的価値

今のWeb開発トレンドは**「SPA疲れ（JavaScript Fatigue）」**からの揺り戻しが起きています。

- 「Reactを入れるほどじゃないけど、画面遷移で白くチカチカするのは嫌だ」
- 「Rails `new` するとファイルが多すぎて管理しきれない」

この層の不満をSalviaはピンポイントで解消します。

- *「賢い（Wise）開発者は、無駄なJSを書かない」**という哲学は、現代において非常に強力な訴求力を持ちます。

開発難易度が低く、効果が高い。

まずはプロトタイプとして作り切る価値は十分にあるプロジェクトだと判定できます。

## Review 5

Salvia.rb における **「Islands Architecture (Salvia Islands)」** の構想を、設計思想・ディレクトリ構成・実装コードまで含めて、「賢い（Wise）」開発者のためのガイド

### 🏝 コンセプト： "The Sea and The Islands"

Webアプリの構造を「海」と「島」に分け、**9割のコードを Ruby (HTML) で記述する** ことで、複雑さを極限まで減らすアーキテクチャです。

| **領域** | **名称** | **技術スタック** | **役割** |
| --- | --- | --- | --- |
| **🌊 海** | **The Sea** | **Ruby (Salvia) + HTMX** | ページの **90%**。静的コンテンツ、遷移、フォーム送信など。サーバーサイドで完結し、高速。 |
| **🏝 島** | **The Islands** | **React (JSX) + Esbuild** | ページの **10%**。リッチエディタ、グラフ、ドラッグ操作など、高度なUIが必要な部分のみ。 |

---

### 📂 1. ディレクトリ構成 (Separation of Concerns)

「Ruby の領土（ERB）」に JSX を侵入させず、ファイルと言語を明確に分離します。

```ruby
myapp/
├── app/
│   ├── views/                  # 🌊 海 (ERB: Rubyの世界)
│   │   └── articles/
│   │       └── edit.html.erb   # <%= island ... %> で場所だけ指定
│   │
│   └── javascript/             # 🏝 島 (JSX: Reactの世界)
│       ├── entry.js            # マウント用スクリプト (The Mounter)
│       └── islands/
│           └── Editor.jsx      # Reactコンポーネント実体
│
├── node_modules/               # 🏭 ビルド用倉庫 (ブラウザには配信しない)
│
└── public/
    └── assets/
        └── islands.js          # 📦 成果物 (バンドルされた単一ファイル)
```

---

### 🌉 2. 実装の仕組み (The Bridge)

Ruby から React へ、データを渡し、起動するためのシンプルな規約です。

### A. Ruby側ヘルパー (The Caller)

`app/helpers/island_helper.rb`

ユーザーは View で `<%= island ... %>` と書くだけ。JSX は書きません。

```ruby
def island(name, props = {}, options = {})# PropsをJSON化して、HTMLのデータ属性に埋め込む
  tag_options = options.merge({
    "data-island" => name,
    "data-props" => props.to_json
  })
  
  # <div data-island="Editor" data-props='{...}'></div> を生成
  tag.div(**tag_options)
end
```

### B. JavaScript側マウンター (The Hydrator)

`app/javascript/entry.js`

ブラウザ上で `data-island` を見つけ、React を起動します。**HTMX の画面更新に対応**しているのがポイントです。

```ruby
import React from 'react';
import { createRoot } from 'react-dom/client';
import Editor from './islands/Editor'; // コンポーネント登録

const ISLANDS = { Editor };

function mountIslands(scope = document) {
  scope.querySelectorAll('[data-island]').forEach(el => {
    if (el.dataset.mounted) return; // 二重起動防止

    const Component = ISLANDS[el.dataset.island];
    const props = JSON.parse(el.dataset.props || '{}');
    
    createRoot(el).render(<Component {...props} />);
    el.dataset.mounted = "true";
  });
}

// 1. 初回ロード時
document.addEventListener('DOMContentLoaded', () => mountIslands());

// 2. HTMXによる書き換え後 (ここが重要！)
document.body.addEventListener('htmx:afterSwap', (e) => mountIslands(e.detail.target));
```

---

### 🏭 3. ビルドプロセス (No Node Server)

Node.js はサーバーとしては使いません。**「ビルドツール」として裏方でのみ** 働きます。

1. **開発:** `node_modules` に React などのライブラリを `npm install` する。
2. **ビルド:** `salvia island:build` コマンドを実行。
    - 内部で `esbuild` が走り、`app/javascript` と `node_modules` を結合。
    - JSX をブラウザ互換の JS に変換。
3. **配信:** 生成された `public/assets/islands.js` (単一ファイル) をブラウザが読み込む。

---

### 💎 Salvia Islands の「知性 (Wisdom)」

このアーキテクチャが Salvia.rb にとって理想的である3つの理由：

1. **言語の純潔性:**
    - RubyファイルにはRubyだけ、JSファイルにはJSだけを書くため、エディタの支援が効きやすく、脳のスイッチ切り替えコストが低い。
2. **疎結合な依存:**
    - Railsのようなサーバーと、Viteのようなビルドシステムが完全に分離しているため、どちらかがアップデートされてもシステム全体が壊れにくい。
3. **"Manual" ゆえの制御:**
    - `<%= island ... %>` と明示的に書くことで、「ここは重い処理（React）を使っている」と開発者が自覚でき、パフォーマンスへの意識が保たれる。

> これが、**Salvia.rb: "Blue Wisdom"** が提案する、現代の Web 開発への回答です。
>