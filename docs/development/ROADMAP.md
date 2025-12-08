# Salvia.rb Roadmap

> "Wisdom for Rubyists." — 小さくて理解しやすい Ruby MVC フレームワーク

---

## Vision

Salvia.rb は「Rails は重すぎる、Sinatra は軽すぎる」という隙間を埋めるフレームワークです。

- **サーバーレンダリング (HTML) ファースト**
- **HTMX 推奨**（Rails の Hotwire のような位置付け）
- **Tailwind CSS** でモダンな見た目（推奨）
- **ActiveRecord** でデータベース操作
- **Node.js 不要**（tailwindcss-ruby を使用）

### HTMX の位置付け

Salvia における HTMX は、**Rails における Hotwire (Turbo/Stimulus)** のような位置付けです：

| 項目 | Rails | Salvia |
|------|-------|--------|
| 推奨技術 | Hotwire (Turbo/Stimulus) | **HTMX** |
| 必須か？ | ❌ 選択可能 | ❌ **選択可能** |
| コア依存 | なし | **なし** |
| 他の選択肢 | React, Vue, Vanilla JS | Preact Islands, Vanilla JS, React |

**Smart Rendering** は HTMX ヘッダーを検出しますが、HTMX がなくても動作します。
他の JavaScript フレームワークや Vanilla JS でも問題なく使えます。

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
- [x] HTMX (htmx.min.js) のプレースホルダー配置（推奨、オプショナル）
- [x] Tailwind CSS の初期設定（推奨、オプショナル）

---

## Phase 1: Developer Experience (v0.2.0) ✅

開発者体験の向上。コードリロードとスマートなレンダリング。

### Smart Rendering（HTMX 推奨）
- [x] `htmx_request?` ヘルパー（HTMX ヘッダーを検出、オプショナル）
- [x] HTMX リクエスト時の自動レイアウト除外（HTMX がない場合は通常レンダリング）
- [x] `render` メソッドの統一（view/partial の自動判定）

**注**: Smart Rendering は HTMX がなくても動作します。HTMX は推奨ですが、必須ではありません。

### Auto-reloading
- [x] Zeitwerk によるオートローディング
- [x] 開発環境でのコードリロード

### Error Handling
- [x] 開発用エラー画面（スタックトレース表示）
- [x] 本番用エラーページ (404, 500)

### CLI Enhancement
- [x] `salvia console` (`salvia c`) - IRB コンソール
- [x] `salvia css:watch` - Tailwind ウォッチモード
- [x] `salvia db:create` / `salvia db:setup`

---

## Phase 2: Security & Stability (v0.3.0) ✅

セキュリティ機能とセッション管理。本番利用に向けた基盤。

### Security
- [x] CSRF 対策（Rack::Protection 統合）
- [x] HTMX 用 CSRF トークン自動送信設定
- [x] `<meta name="csrf-token">` ヘルパー

### Session Management
- [x] Cookie ベースセッション（Rack::Session::Cookie）
- [x] `session` ヘルパー
- [x] `flash` メッセージ（flash[:notice], flash[:alert]）

### Routing Enhancement
- [x] `resources` DSL の完全実装
- [x] ネストしたリソース
- [x] 名前付きルート（`*_path` ヘルパー）

---

## Phase 3: Production Ready (v0.4.0) ✅

本番運用に必要な機能。

### Asset Management
- [x] アセットダイジェスト（キャッシュバスティング）
- [x] `asset_path` ヘルパー
- [x] `assets:precompile` コマンド

### Logging & Monitoring
- [x] `Salvia.logger` の実装
- [x] 環境ごとのログ設定 (`config/environments/*.rb`)
- [x] Rack::CommonLogger との統合

### Testing Support
- [x] `Salvia::Test::ControllerHelper`
- [x] `rack-test` 統合
- [x] テストジェネレーター (`salvia new` で `test/` 生成)

### Documentation
- [x] セキュリティガイド & 評価レポート
- [x] 実装ドキュメント (IMPLEMENTATION.md)

---

## Phase 4: Rich UI & Advanced Features (v0.5.0)

よりリッチな UI と高度な機能のサポート。

### HTMX Helpers
- [ ] `htmx_link_to` ヘルパー
- [ ] `htmx_form_for` ヘルパー
- [ ] `htmx_trigger` レスポンスヘッダー設定ヘルパー

### View Components
- [ ] `component` ヘルパー (View Component パターン)
- [ ] Tailwind クラスのカプセル化支援
- [ ] UI プリセット（Button, Card, Modal）

### Advanced Features
- [ ] WebSocket サポート（ActionCable 的な機能）
- [ ] バックグラウンドジョブ統合ガイド (Sidekiq / Solid Queue)
- [ ] マルチテナント対応ガイド

---

## Phase 5: Salvia Islands (v0.6.0)

> **"HTML ファーストを維持しながら、必要な部分だけリッチに"**
> Node.js 不要で Island Architecture を実現する。

### Core Islands
- [ ] Import Maps 自動生成・管理
- [ ] `island` ビューヘルパー
- [ ] Preact + HTM 統合

### TypeScript Support (Client)
- [ ] `salvia types:generate` - ActiveRecord から TypeScript 型定義を生成
- [ ] `salvia client:generate` - ルーティングから API クライアントを生成
- [ ] esm.sh を利用したビルドレス TypeScript 実行環境の整備

---

## v1.0.0: Stable Release

これら全ての機能が実装され、安定稼働することを確認して初めて v1.0.0 としてリリースします。

### Final Polish
- [ ] Getting Started ガイドの完成
- [ ] API リファレンスの整備
- [ ] デプロイガイド（Render, Fly.io, Heroku, Kamal）
- [ ] パフォーマンスチューニング
- [ ] バグ修正と安定化

---

## Future (v1.1+)

v1.0 以降の拡張機能。

### Ecosystem
- [ ] 公式 Island コンポーネント集 (`<salvia-chart>`, `<salvia-editor>`)
- [ ] 管理画面ジェネレーター (Salvia Admin)


## 🏝️ Salvia Islands (Concept)

> **"HTML ファーストを維持しながら、必要な部分だけリッチに"**
>
> Node.js 不要で Island Architecture を実現する革命的アプローチ。
> Phase 5 (v0.6.0) での実装を目指します。

### コンセプト

```
┌─────────────────────────────────────────────────────────┐
│              Salvia (HTML + HTMX)                       │
│  ┌─────────────────────────────────────────────────┐   　│
│  │  90% サーバーレンダリング（従来通り）           　　　│   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────────────┐ │   │
│  │  │ Island  │  │ Island  │  │     HTML        │ │   │
│  │  │ (Chart) │  │(Editor) │  │   (HTMX で十分) │ │   │
│  │  └─────────┘  └─────────┘  └─────────────────┘ │   │
│  │  10% クライアントサイド（複雑なUIのみ）        │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 技術スタック

**Node.js 不要** を維持するため、以下のアプローチを採用：

#### 基盤: Import Maps + ESM (ビルドレス)
```html
<!-- layouts/application.html.erb で設定 -->
<script type="importmap">
{
  "imports": {
    "preact": "https://esm.sh/preact@10",
    "preact/hooks": "https://esm.sh/preact@10/hooks",
    "htm/preact": "https://esm.sh/htm@3/preact",
    "lit": "https://esm.sh/lit@3",
    "chart.js": "https://esm.sh/chart.js@4"
  }
}
</script>
```
- CDN から直接 import（esm.sh）
- 開発時ビルド不要
- Deno Fresh / Astro に近いアプローチ

#### Option A: Preact + HTM（推奨）
```javascript
// app/islands/Counter.js
import { useState } from 'preact/hooks';
import { html } from 'htm/preact';

export function Counter({ initial = 0 }) {
  const [count, setCount] = useState(initial);
  
  return html`
    <div class="counter">
      <span class="text-2xl font-bold">${count}</span>
      <button 
        class="bg-salvia-500 text-white px-4 py-2 rounded"
        onClick=${() => setCount(c => c + 1)}
      >
        +1
      </button>
    </div>
  `;
}
```
- **Preact** (3KB) - React 互換、超軽量
- **HTM** - JSX なしで React ライクな記法（タグ付きテンプレートリテラル）
- React エコシステムの多くが使える
- Hooks（useState, useEffect 等）完全サポート

#### Option B: Web Components (Lit)
```javascript
// app/islands/MyChart.js
import { LitElement, html, css } from 'lit';

class MyChart extends LitElement {
  static properties = { data: { type: Array } };
  
  render() {
    return html`<canvas id="chart"></canvas>`;
  }
}
customElements.define('my-chart', MyChart);
```
- **Lit** (5KB) - Web Components を簡単に
- Shadow DOM でスタイル分離
- ブラウザ標準技術

#### 選択ガイド

| ユースケース | 推奨 |
|--------------|------|
| React に慣れている | **Preact + HTM** |
| 状態管理が複雑 | **Preact + HTM** |
| 完全にカプセル化したい | **Lit (Web Components)** |
| 既存の React ライブラリを使いたい | **Preact + HTM** |
| 最小限の学習コスト | **Preact + HTM** |

### TypeScript サポート

**結論: TypeScript で書いて、ビルドレスで実行**

#### アプローチ: esm.sh の自動変換

```
┌─────────────────────────────────────────────────────────┐
│  開発時: TypeScript で書く (.ts)                          │
│  ├─ VS Code が型チェック・補完                             │
│  └─ エラーを事前に検出                                     │
├─────────────────────────────────────────────────────────┤
│  実行時 esm.sh / ブラウザが処理                             │
│  └─ .ts → .js を CDN が自動変換                           │
│     Node.js / ビルドステップ不要                           │
└─────────────────────────────────────────────────────────┘
```

#### Island を TypeScript で書く

```typescript
// app/islands/Counter.ts
import { useState } from 'preact/hooks';
import { html } from 'htm/preact';
import type { User } from './types.ts';

interface CounterProps {
  initial: number;
  user: User;
}

export function Counter({ initial, user }: CounterProps) {
  const [count, setCount] = useState(initial);
  
  return html`
    <div class="counter">
      <span>${user.name}: ${count}</span>
      <button onClick=${() => setCount(c => c + 1)}>+1</button>
    </div>
  `;
}
```

#### 型定義ファイル（自動生成）

```typescript
// app/islands/types.ts (salvia types:generate で生成)
export interface User {
  id: number;
  name: string;
  email: string;
  age: number | null;
  created_at: string;
  updated_at: string;
}

export interface Post {
  id: number;
  title: string;
  body: string;
  user_id: number;
}
```

#### Import Maps 設定

```html
<!-- layouts/application.html.erb -->
<script type="importmap">
{
  "imports": {
    "preact": "https://esm.sh/preact@10",
    "preact/hooks": "https://esm.sh/preact@10/hooks",
    "htm/preact": "https://esm.sh/htm@3/preact"
  }
}
</script>

<!-- TypeScript ファイルを直接読み込み（esm.sh が変換） -->
<script type="module" src="/islands/Counter.ts"></script>
```

#### 開発時の型チェック（オプション）

```bash
# tsconfig.json を用意すれば、IDE が型チェック
# ビルドは不要、型チェックのみ
npx tsc --noEmit
```

**哲学: TypeScript の恩恵を受けつつ、Node.js ビルド不要を維持** 🌿

### 実装計画

#### Phase 5: Salvia Islands (v0.6.0)
- [ ] `island` ビューヘルパー
- [ ] Import Maps の自動生成
- [ ] Props の JSON シリアライズ
- [ ] 基本的な Web Component テンプレート
- [ ] HTMX `afterSwap` での Island 自動再マウント
- [ ] Lazy Loading（Intersection Observer）

#### Future (v1.1+)
- [ ] 公式 Island コンポーネント集
  - `<salvia-chart>` - Chart.js ラッパー
  - `<salvia-editor>` - リッチテキストエディタ
  - `<salvia-calendar>` - カレンダー
  - `<salvia-autocomplete>` - オートコンプリート
- [ ] Island Component Generator (`salvia g island NAME`)

### 使用イメージ

```erb
<!-- app/views/dashboard/index.html.erb -->
<div class="dashboard">
  <h1>ダッシュボード</h1>
  
  <!-- 普通の HTMX（これで十分な部分） -->
  <div hx-get="/notifications" hx-trigger="every 30s">
    <%= render "notifications/_list" %>
  </div>

  <!-- Preact Island: 複雑なインタラクションが必要な部分だけ -->
  <%= island "Counter", { initial: 10 } %>
  
  <%= island "SalesChart", { 
    data: @sales_data, 
    type: "line",
    title: "月間売上" 
  } %>
  
  <!-- 遅延読み込み（スクロールで表示時に初期化） -->
  <%= island "Calendar", { events: @events }, lazy: true %>
  
  <!-- Lit Web Component も混在可能 -->
  <%= island "my-rich-editor", { content: @draft.body }, type: :lit %>
</div>
```

### Island ファイル構造

```
app/
├── islands/                    # Preact / Lit コンポーネント
│   ├── Counter.js              # Preact + HTM
│   ├── SalesChart.js           # Preact + Chart.js
│   ├── Calendar.js             # Preact
│   └── components/             # 共有コンポーネント
│       ├── Button.js
│       └── Modal.js
└── views/
    └── layouts/
        └── application.html.erb  # Import Maps 定義
```

### なぜ革命的か

| 従来 | Salvia Islands |
|------|----------------|
| SPA vs SSR の二択 | 両方のいいとこ取り |
| React なら全部 React | 必要な所だけ JS |
| npm/webpack 必須 | **Node.js 不要** |
| 複雑なビルド設定 | Import Maps でシンプル |
| Ruby と JS の分断 | ERB から自然に統合 |

### 参考にする既存技術

- **Astro** - Island Architecture の先駆者
- **Deno Fresh** - Import Maps + Preact
- **Hotwire (Turbo/Stimulus)** - Rails の部分的 JS
- **htmx** - HTML ファーストの思想

---

## 🔮 Salvia Types / Client (実験的構想)

> **Ruby と JavaScript の型・API を繋ぐ** - tRPC にインスパイアされた構想

### コンセプト

```
┌─────────────────────────────────────────────────────────┐
│                    Source of Truth                      |
│    routes.rb / schema / Sorbet / ActiveRecord           │
└─────────────────────────────────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │  Ruby 型  │   │  JS 型   │   │ Client   │
    │ (Sorbet) │   │ (JSDoc)  │   │ (fetch)  │
    └──────────┘   └──────────┘   └──────────┘
```

### アプローチ一覧

#### Pattern A: routes.rb → TypeScript Client 自動生成

**コンセプト**: ルーティング定義から型付き API クライアントを自動生成

```ruby
# config/routes.rb
Salvia::Router.draw do
  resources :users
  resources :posts do
    resources :comments
  end
end
```

↓ `salvia client:generate`

```typescript
// app/islands/client.ts (自動生成)
export const salvia = {
  users: {
    index: (): Promise<unknown[]> => 
      fetch('/users').then(r => r.json()),
    show: (id: number): Promise<unknown> => 
      fetch(`/users/${id}`).then(r => r.json()),
    create: (data: Record<string, unknown>): Promise<unknown> => 
      fetch('/users', { method: 'POST', body: JSON.stringify(data) }).then(r => r.json()),
    update: (id: number, data: Record<string, unknown>): Promise<unknown> => 
      fetch(`/users/${id}`, { method: 'PATCH', body: JSON.stringify(data) }).then(r => r.json()),
    destroy: (id: number): Promise<void> => 
      fetch(`/users/${id}`, { method: 'DELETE' }).then(() => {}),
  },
  posts: {
    comments: {
      index: (postId: number): Promise<unknown[]> => 
        fetch(`/posts/${postId}/comments`).then(r => r.json()),
    }
  }
};
```

**メリット**: シンプル、REST のまま、基本的な型付き
**デメリット**: 戻り値の型は `unknown`（Pattern B-E と組み合わせて改善）

---

#### Pattern B: ActiveRecord → TypeScript 型生成

**コンセプト**: DB スキーマから TypeScript の型定義を自動生成

```ruby
# db/schema.rb
create_table "users" do |t|
  t.string "name", null: false
  t.string "email", null: false
  t.integer "age"
  t.timestamps
end
```

↓ `salvia types:generate`

```typescript
// app/islands/types.ts (自動生成)
export interface User {
  id: number;
  name: string;
  email: string;
  age: number | null;
  created_at: string;
  updated_at: string;
}

export interface Post {
  id: number;
  title: string;
  body: string;
  user_id: number;
}
```

**メリット**: DB スキーマが Source of Truth、自動同期、TypeScript の恩恵
**デメリット**: API レスポンスと完全一致とは限らない

---

#### Pattern C: Sorbet RBI → TypeScript 変換

**コンセプト**: Sorbet の型定義から TypeScript 型を生成

```ruby
# sorbet/rbi/user.rbi
class User
  sig { returns(Integer) }
  def id; end

  sig { returns(String) }
  def name; end

  sig { returns(T.nilable(Integer)) }
  def age; end
end
```

↓ `salvia types:from_sorbet`

```typescript
// app/islands/types.ts
export interface User {
  id: number;
  name: string;
  age: number | null;
}
```

**メリット**: Sorbet ユーザーには自然、Ruby 側も型安全、完全な型共有
**デメリット**: Sorbet 導入が前提、変換ロジックが複雑

---

#### Pattern D: JSON Schema 共通定義

**コンセプト**: 言語に依存しないスキーマから両方生成

```yaml
# schema/user.yml
User:
  type: object
  properties:
    id:
      type: integer
    name:
      type: string
    email:
      type: string
      format: email
    age:
      type: integer
      nullable: true
  required: [id, name, email]
```

↓ `salvia schema:generate`

```ruby
# app/types/user.rb (Ruby/Sorbet)
class User < T::Struct
  prop :id, Integer
  prop :name, String
  prop :email, String
  prop :age, T.nilable(Integer)
end
```

```typescript
// app/islands/types.ts (TypeScript)
export interface User {
  id: number;
  name: string;
  email: string;
  age: number | null;
}
```

**メリット**: 言語非依存、OpenAPI/GraphQL と親和性高い、完全な型安全
**デメリット**: スキーマを別途管理、二重定義感

---

#### Pattern E: Controller アノテーション

**コンセプト**: Controller の戻り値を明示的にアノテーション

```ruby
class UsersController < ApplicationController
  # @return [Array<User>]
  def index
    @users = User.all
    render json: @users
  end

  # @param id [Integer]
  # @return [User]
  def show
    @user = User.find(params[:id])
    render json: @user
  end
end
```

↓ `salvia client:generate`

```typescript
// app/islands/client.ts
import type { User } from './types';

export const salvia = {
  users: {
    index: (): Promise<User[]> => 
      fetch('/users').then(r => r.json()),
    
    show: (id: number): Promise<User> => 
      fetch(`/users/${id}`).then(r => r.json()),
    
    create: (data: Omit<User, 'id' | 'created_at' | 'updated_at'>): Promise<User> =>
      fetch('/users', { 
        method: 'POST', 
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data) 
      }).then(r => r.json()),
  }
};
```

**メリット**: 型情報が API に紐付く、完全な型安全、IDE 補完
**デメリット**: アノテーション記述が必要

---

#### Pattern F: GraphQL スキーマ

**コンセプト**: GraphQL スキーマから Ruby と TypeScript の型を生成

```graphql
# schema.graphql
type User {
  id: ID!
  name: String!
  email: String!
  age: Int
  posts: [Post!]!
}

type Post {
  id: ID!
  title: String!
  body: String!
  author: User!
}

type Query {
  users: [User!]!
  user(id: ID!): User
  posts: [Post!]!
}
```

↓ `salvia types:from_graphql`

```ruby
# app/types/user.rb (自動生成)
class User < T::Struct
  prop :id, String
  prop :name, String
  prop :email, String
  prop :age, T.nilable(Integer)
  prop :posts, T::Array[Post]
end
```

```typescript
// app/islands/types.ts (自動生成)
export interface User {
  id: string;
  name: string;
  email: string;
  age: number | null;
  posts: Post[];
}

export interface Post {
  id: string;
  title: string;
  body: string;
  author: User;
}
```

**メリット**: GraphQL エコシステムと統合、クエリ型も自動生成可能
**デメリット**: GraphQL サーバーが必要、REST とは別のアプローチ

---

#### Pattern G: OpenAPI / Swagger

**コンセプト**: OpenAPI 仕様から両言語の型とクライアントを生成

```yaml
# openapi.yml
openapi: 3.0.0
info:
  title: Salvia API
  version: 1.0.0

paths:
  /users:
    get:
      summary: List users
      responses:
        '200':
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'
  
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
        email:
          type: string
          format: email
        age:
          type: integer
          nullable: true
      required: [id, name, email]
```

↓ `salvia types:from_openapi`

```ruby
# app/types/user.rb (自動生成)
class User < T::Struct
  prop :id, Integer
  prop :name, String
  prop :email, String
  prop :age, T.nilable(Integer)
end
```

```typescript
// app/islands/types.ts (自動生成)
export interface User {
  id: number;
  name: string;
  email: string;
  age: number | null;
}

// app/islands/client.ts (自動生成)
export const salvia = {
  users: {
    index: (): Promise<User[]> => 
      fetch('/users').then(r => r.json()),
  }
};
```

**メリット**: 業界標準、ツールエコシステム豊富、API ドキュメントも自動生成
**デメリット**: OpenAPI 仕様を維持する必要

---

#### Pattern H: Protocol Buffers (Protobuf)

**コンセプト**: .proto ファイルから多言語の型を生成

```protobuf
// schema/user.proto
syntax = "proto3";

message User {
  int32 id = 1;
  string name = 2;
  string email = 3;
  optional int32 age = 4;
  repeated Post posts = 5;
}

message Post {
  int32 id = 1;
  string title = 2;
  string body = 3;
  User author = 4;
}
```

↓ `salvia types:from_protobuf`

```ruby
# app/types/user.rb (自動生成 via protobuf-ruby)
class User < Google::Protobuf::MessageExts::ClassMethods
  # protobuf の Ruby 実装
end
```

```typescript
// app/islands/types.ts (自動生成 via protobufjs)
export interface User {
  id: number;
  name: string;
  email: string;
  age?: number;
  posts: Post[];
}
```

**メリット**: バイナリ効率、gRPC と統合可能、言語非依存
**デメリット**: バイナリ形式、REST とは異なる、学習コスト

---

### パターン比較

| Pattern | Source of Truth | 難易度 | 型の正確さ | おすすめ度 |
|---------|-----------------|--------|-----------|-----------|
| **A** | routes.rb | ★☆☆ | △ unknown | 入門向け |
| **B** | ActiveRecord | ★★☆ | ○ DB 基準 | **実用的** |
| **C** | Sorbet | ★★★ | ◎ 完全 | Sorbet 使うなら |
| **D** | JSON Schema | ★★☆ | ◎ 完全 | API 重視なら |
| **E** | Controller | ★★☆ | ◎ 明示的 | **バランス良い** |
| **F** | GraphQL | ★★★ | ◎ 完全 | GraphQL 使うなら |
| **G** | OpenAPI | ★★☆ | ◎ 完全 | **API 標準重視** |
| **H** | Protobuf | ★★★ | ◎ 完全 | gRPC / 高性能重視 |

### 組み合わせ推奨

```
Pattern A (Client) + Pattern B (Types) = 最小構成
Pattern A (Client) + Pattern E (Types) = 最も正確
Pattern G (OpenAPI) = 業界標準、API ドキュメントも自動生成
Pattern F (GraphQL) = GraphQL エコシステムと統合
Pattern H (Protobuf) = 高性能 / gRPC が必要な場合
```

### 推奨アプローチ

```
Phase 1: Pattern A (routes → Client)
         まずシンプルに API クライアントを自動生成

Phase 2: Pattern B (ActiveRecord → Types)
         DB スキーマから TypeScript 型を生成

Phase 3: Pattern E (Controller アノテーション)
         より正確な型情報を提供

Future:  Pattern C/D/F/G/H
         Sorbet、JSON Schema、GraphQL、OpenAPI、Protobuf との統合
```

### 標準スキーマ形式の選択ガイド

| 要件 | 推奨パターン |
|------|-------------|
| REST API を標準化したい | **Pattern G (OpenAPI)** |
| GraphQL を使っている | **Pattern F (GraphQL)** |
| 高性能 / gRPC が必要 | **Pattern H (Protobuf)** |
| シンプルに始めたい | **Pattern A + B** |
| 既存の JSON Schema がある | **Pattern D** |

### tRPC との比較

| 項目 | tRPC | Salvia Types/Client |
|------|------|---------------------|
| 言語 | TS ↔ TS | **Ruby ↔ TS** |
| 型共有 | 自動 | 生成ベース |
| プロトコル | 独自 RPC | **REST (標準)** |
| ビルド | 必要 | **不要 (esm.sh)** |
| HTMX 共存 | 難しい | **自然に共存** |
| 学習コスト | 高い | **低い** |
| TypeScript | 必須 | **オプション** |

### 生成されるファイル

```
app/
├── islands/
│   ├── client.ts        # 自動生成: 型付き API クライアント
│   ├── types.ts         # 自動生成: TypeScript 型定義
│   ├── Counter.ts       # 開発者が書く Island
│   └── UserList.ts      # 開発者が書く Island
```

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

*最終更新: 2025-01*

