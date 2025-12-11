# Wisdom for Salvia: The Architecture of True HTML First

## 1. The Road to Sage (Vision)

Salvia is not just a view engine; it is the foundational technology for **Sage**, a future Ruby MVC framework designed from the ground up for the "True HTML First" era.

While Sage is in development, Salvia brings this futuristic architecture to **Ruby on Rails** today. It allows Rails developers to abandon ERB/Slim and adopt a modern, component-based frontend workflow without leaving the Ruby ecosystem.

## 2. The Architecture: Rails + JSX

Salvia replaces the traditional Rails View layer entirely with JSX/TSX, while keeping the robust backend logic of Ruby (Controllers & Models).

**Architecture Comparison:**

| Feature | Rails (Traditional) | Next.js (App Router) | Salvia (Rails + JSX) |
| :--- | :--- | :--- | :--- |
| **Routing** | Ruby (routes.rb) | File-system (JS) | Ruby (routes.rb) |
| **Data Fetching** | Ruby (Controller) | JS (Server Components) | Ruby (Controller) |
| **View Logic** | ERB (Ruby) | JSX (React) | **JSX (Preact/React)** |
| **Interactivity** | Stimulus / Turbo | React (Hydration) | **Islands (Hydration)** |
| **Build Step** | Asset Pipeline / Vite | Webpack / Turbopack | **No Build (JIT via Deno)** |

In Salvia, your Rails controller fetches data from the database (ActiveRecord) and passes it directly to a **Server Component (Page)**. This component is rendered to HTML on the server (SSR) and sent to the browser.

*   **Zero JS by default**: Static content is just HTML.
*   **Islands Architecture**: Only interactive parts (Islands) are hydrated with JavaScript.

## 3. Directory Structure (The "Salvia" Directory)

To separate the frontend concerns from the Ruby backend, Salvia introduces a `salvia/` directory at the project root.

```
my_app/
├── app/                   # Ruby Backend (Controllers, Models)
│   ├── controllers/
│   └── models/
├── config/                # Rails/Sinatra Config
├── salvia/                # Frontend Root (Deno/TypeScript)
│   ├── deno.json          # Import Map & Dependencies
│   ├── vendor_setup.ts    # Bridge for SSR Global Scope
│   └── app/
│       ├── pages/         # Server Components (Entry Points)
│       │   └── Home.tsx
│       ├── islands/       # Client Components (Interactive)
│       │   └── Counter.tsx
│       └── components/    # Shared UI Components
│           └── Button.tsx
└── public/                # Static Assets
```

## 3. Unified Import Management (The "One Config" Strategy)

Salvia v0.2.0 introduces a unified way to manage frontend dependencies using `deno.json`. This single file controls imports for:
1.  **Browser (Client-side)**: Via Import Maps generated in HTML.
2.  **SSR (Server-side)**: Via Deno/QuickJS module resolution.
3.  **Type Checking**: Via Deno's native TypeScript support.

### How it works

You define your dependencies in `salvia/deno.json`:

```json
{
  "imports": {
    // Framework Aliases (Required)
    "framework": "npm:preact@10.19.3",
    "framework/hooks": "npm:preact@10.19.3/hooks",
    "framework/jsx-runtime": "npm:preact@10.19.3/jsx-runtime",
    "framework/ssr": "npm:preact-render-to-string@6.3.1",

    // Other Libraries
    "uuid": "npm:uuid@9.0.1",
    "canvas-confetti": "npm:canvas-confetti@1.9.2"
  }
}
```

**Key Concepts:**

*   **`framework` alias**: Salvia uses this alias internally to support multiple frameworks (Preact, React, etc.) without changing the core logic. You simply point `framework` to your chosen library.
*   **`npm:` specifiers**: Deno uses these to fetch packages from npm. Salvia automatically converts these to `https://esm.sh/...` URLs when generating the Import Map for the browser, ensuring browser compatibility without a build step.

### `vendor_setup.ts` (The Bridge)

To make these ESM modules available to the QuickJS SSR engine (which doesn't natively support `npm:` imports or complex module resolution), we use a bridge file called `salvia/vendor_setup.ts`.

This file imports the framework and libraries using the aliases defined in `deno.json` and exposes them to the global scope for QuickJS.

```typescript
// salvia/vendor_setup.ts
import { h, options } from "framework";
import { renderToString } from "framework/ssr";

// Expose to QuickJS global scope
(globalThis as any).h = h;
(globalThis as any).renderToString = renderToString;

// Setup other globals if needed
import { v4 as uuidv4 } from "uuid";
(globalThis as any).uuidv4 = uuidv4;
```

**Why is this necessary?**
QuickJS is a lightweight engine. By bundling `vendor_setup.ts` using Deno (which understands `npm:` and `deno.json`), we create a single self-contained JavaScript file (`vendor.js`) that contains all your dependencies. QuickJS simply loads this file, and *boom*, `h` and `renderToString` are available globally.

## 4. Multi-Framework Support

Thanks to the `framework` alias strategy, switching frameworks is (theoretically) as simple as updating `deno.json`.

**To use React (Future):**

```json
{
  "imports": {
    "framework": "npm:react@18.2.0",
    "framework/client": "npm:react-dom@18.2.0/client",
    "framework/jsx-runtime": "npm:react@18.2.0/jsx-runtime",
    "framework/ssr": "npm:react-dom@18.2.0/server"
  }
}
```

*Note: React support is currently experimental. Preact is the default and recommended framework for Salvia due to its lightweight nature and compatibility.*

## 5. JIT Compilation & The Sidecar

Salvia uses a "Managed Sidecar" architecture to provide instant feedback during development.

1.  **Rails/Sinatra** starts a background Deno process (`sidecar.ts`).
2.  When you request a page, the **DevServer** middleware intercepts requests for `.js` files.
3.  It asks the **Sidecar** to compile the corresponding `.tsx` file on-the-fly using `esbuild`.
4.  The compiled JS is served to the browser (or used for SSR).

This eliminates the need for a separate `npm run build` or `deno task watch` command. You just run `rails s` or `ruby app.rb`, and Salvia handles the rest.

## 6. The Ultimate Salvia Stack: Salvia + Turbo + Signals

Salvia、Turbo (Drive/Frames/Streams)、そして Preact Signals。これらを組み合わせることで、**「サーバーサイドの単純さ」と「クライアントサイドのリッチさ」を完全に両立**する、現代の Web 開発における「最強のスタック」が完成します。

### 1. 各技術の役割とシナジー

| 技術 | 役割 (Role) | 利点 (Benefit) |
| :--- | :--- | :--- |
| **Salvia** | **Renderer** (HTML生成) | **初期表示が爆速**。サーバーで JSX を HTML に変換するため、クライアントの JS 負荷が最小限。SEO にも強い。 |
| **Turbo Drive** | **Navigator** (画面遷移) | **SPA のような滑らかさ**。リンクとフォームをインターセプトし、ページ全体をリロードせずに `<body>` だけを差し替える。 |
| **Turbo Frames** | **Decomposer** (部分置換) | **画面の分割統治**。ページ内の一部分（例: モーダル、サイドバー）だけを独立して更新・遅延読み込みできる。 |
| **Turbo Streams** | **Broadcaster** (リアルタイム) | **Live 更新**。WebSocket (ActionCable) を通じて、サーバーからプッシュで HTML を追加・削除・更新する。 |
| **Preact Signals** | **State Manager** (状態管理) | **超高速な局所更新**。Island 内の複雑な状態を管理。値が変わった時、コンポーネント全体を再レンダリングせず、DOM を直接ピンポイントで書き換える。 |

### 2. 統合によるメリット (The "Why")

このスタックを採用すると、**「JSON API を書く必要」がほぼなくなります**。

1.  **ロジックはサーバー (Ruby) に集約**: 複雑なバリデーション、権限管理、DB 操作はすべて Rails/Sinatra が担当。
2.  **UI は宣言的 (JSX)**: 現代的なコンポーネント指向で UI を構築。ERB のような「混ぜ書き」カオスから解放されます。
3.  **通信は HTML (Turbo)**: クライアントは JSON をパースして DOM を組み立てる必要がありません。サーバーから送られてきた HTML をそのまま表示するだけです。
4.  **対話性は局所化 (Islands + Signals)**: ドラッグ＆ドロップや複雑な計算など、どうしても JS が必要な場所だけ Island 化し、Signals で効率的に管理します。

---

### 3. 実例: リアルタイム・在庫管理ダッシュボード

**シナリオ**:
1.  商品一覧ページ。
2.  **Turbo Streams**: 誰かが在庫を更新すると、閲覧している全員の画面で「在庫数」がリアルタイムに変わる。
3.  **Preact Signals**: 「カートに入れる」ボタンを押すと、ヘッダーの「カート内の点数」が即座に増える（サーバー通信なしで UI 反映）。
4.  **Turbo Drive**: ページ遷移してもカートの状態（Signals）は維持される。

#### A. State Management (Signals)
カートの状態を管理するグローバルな Signal を定義します。

```typescript
// salvia/app/islands/store.ts
import { signal, computed } from "@preact/signals";

export const cartItems = signal<number[]>([]);

export const cartCount = computed(() => cartItems.value.length);

export function addToCart(productId: number) {
  cartItems.value = [...cartItems.value, productId];
}
```

#### B. Client Components (Islands)
Signals を使って、カートボタンとヘッダーを作ります。

```tsx
// salvia/app/islands/HeaderCart.tsx
import { h } from "preact";
import { cartCount } from "./store.ts";

export default function HeaderCart() {
  // cartCount.value が変わると、ここの数字だけが書き換わる
  return (
    <div class="cart-icon">
      🛒 <span class="badge">{cartCount}</span>
    </div>
  );
}
```

```tsx
// salvia/app/islands/AddToCartButton.tsx
import { h } from "preact";
import { addToCart } from "./store.ts";

export default function AddToCartButton({ productId }: { productId: number }) {
  return (
    <button 
      onClick={() => addToCart(productId)}
      class="bg-blue-500 text-white px-4 py-2 rounded"
    >
      Add to Cart
    </button>
  );
}
```

#### C. Server Components (Pages) & Turbo Streams
Rails 側で在庫更新時に Turbo Stream をブロードキャストします。

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  # 在庫が変わったら、products/index ページの該当部分を更新する HTML を配信
  after_update_commit do
    broadcast_replace_to "products",
      target: "product_#{id}_stock",
      partial: "products/stock",
      locals: { product: self }
  end
end
```

```tsx
// salvia/app/pages/products/Index.tsx (Server Component)
import { h } from "preact";
import HeaderCart from "../../islands/HeaderCart.tsx";
import AddToCartButton from "../../islands/AddToCartButton.tsx";

export default function ProductList({ products }) {
  return (
    <div>
      <header class="flex justify-between p-4 border-b">
        <h1>My Shop</h1>
        {/* ページ遷移しても状態が維持されるカート */}
        <Island name="HeaderCart" component={HeaderCart} />
      </header>

      {/* Turbo Stream の購読を開始 */}
      <turbo-cable-stream-source channel="Turbo::Streams::Channel" signed-stream-name="products" />

      <div class="grid grid-cols-3 gap-4 p-4">
        {products.map(product => (
          <div class="border p-4 rounded" id={`product_${product.id}`}>
            <h2>{product.name}</h2>
            
            {/* ここが Turbo Stream でリアルタイム更新されるターゲット */}
            <div id={`product_${product.id}_stock`}>
              Stock: {product.stock}
            </div>

            <Island 
              name="AddToCartButton" 
              component={AddToCartButton} 
              props={{ productId: product.id }} 
            />
          </div>
        ))}
      </div>
    </div>
  );
}
```

この構成により、**「在庫はサーバー主導でリアルタイム同期」「カートはクライアント主導でサクサク動作」** という、理想的な UX が実現できます。

## 7. Props vs Signals: 状態管理のパラダイムシフト

Salvia では、データの流れを理解し、適切なツールを選ぶことが重要です。

### 1. Props (The Waterfall)
**用途**: サーバー (Rails) からクライアント (Island) への初期データの受け渡し。

*   **方向**: 親 (Rails Controller/Page) -> 子 (Island Component)。
*   **特徴**: 不変 (Immutable)。一度レンダリングされたら、親が再レンダリングしない限り変わらない。
*   **Salviaでの役割**: データベースの値 (ActiveRecord) を UI に表示するために使う。

```tsx
// Rails (Controller) -> Page -> Island
<Island name="UserProfile" props={{ name: @user.name, role: "admin" }} />
```

### 2. Signals (The Teleport)
**用途**: クライアントサイドでの動的なインタラクション。

*   **方向**: 状態 (Signal) <-> コンポーネント (Anywhere)。
*   **特徴**: 反応的 (Reactive)。値が変わると、それを使っている場所だけが即座に更新される。
*   **Salviaでの役割**: ユーザーの操作 (クリック、入力) による変化を管理する。

```tsx
// Client Side Only
const count = signal(0);
// ...
<button onClick={() => count.value++}>{count}</button>
```

### 3. 使い分けの指針 (Best Practices)

| シチュエーション | 推奨 (Recommended) | 理由 |
| :--- | :--- | :--- |
| **DBから取得したデータを表示する** | **Props** | サーバーで確定した値であり、クライアントで変更する必要がないため。 |
| **フォームの入力値、トグルボタン** | **Signals** | ユーザー操作によって頻繁に変わり、即座に UI に反映する必要があるため。 |
| **ショッピングカート、通知バッジ** | **Signals (Global)** | 複数のコンポーネント (ヘッダーと商品一覧など) で状態を共有するため。 |
| **ページ遷移 (リンク)** | **Turbo Drive** | JS で状態管理するよりも、URL を変えて新しい HTML を取得する方がシンプルで堅牢。 |

**結論**:
*   **Props** で初期状態を作り、
*   **Signals** で動きをつけ、
*   **Turbo** でページを繋ぐ。

これが Salvia の "Golden Triangle" です。
