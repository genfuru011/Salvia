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
├── config/                # Rails Config
├── salvia/                # Frontend Root (Deno/TypeScript)
│   └── app/
│       ├── pages/         # Server Components (Entry Points)
│       │   └── Home.tsx
│       ├── islands/       # Client Components (Interactive)
│       │   └── Counter.tsx
│       └── components/    # Shared UI Components
│           └── Button.tsx
└── public/                # Static Assets
```

## 4. Zero Config Architecture (Internalized Complexity)

Salvia v0.2.0 adopts a **Zero Config** philosophy, inspired by Next.js and Fresh.

### Internalized Configuration
Previously exposed configuration files like `vendor_setup.ts` are now internalized within the Salvia gem. `deno.json` remains in your project root as the Single Source of Truth for dependencies. This means:

1.  **No Boilerplate**: You don't need to manage complex build configurations or import maps.
2.  **Preact Only**: Salvia is opinionated and strictly enforces a Preact + Signals architecture for maximum performance and compatibility.
3.  **Automatic Import Maps**: Salvia automatically generates Import Maps for the browser based on its internal configuration, ensuring that `preact`, `preact/hooks`, and `@preact/signals` just work.

### How it works under the hood

While complex configuration files like `vendor_setup.ts` are hidden, `deno.json` remains exposed in your project root. This allows you to easily manage dependencies:

1.  **Browser (Client-side)**: Via Import Maps generated in HTML.
2.  **SSR (Server-side)**: Via Deno/QuickJS module resolution using the internal `deno.json`.
3.  **Type Checking**: Via Deno's native TypeScript support.

**Key Concepts:**

*   **Preact First**: Salvia is built on Preact for its lightweight nature and powerful Signals architecture.
*   **`npm:` specifiers**: Deno uses these to fetch packages from npm. Salvia automatically converts these to `https://esm.sh/...` URLs when generating the Import Map for the browser.

### `vendor_setup.ts` (The Bridge)

To make ESM modules available to the QuickJS SSR engine, Salvia uses an internal bridge file called `vendor_setup.ts`. This file imports Preact and Signals and exposes them to the global scope for QuickJS.

```typescript
// Internal vendor_setup.ts
import { h, Fragment } from "preact";
import * as preact from "preact";
import * as hooks from "preact/hooks";
import * as signals from "@preact/signals";
import { renderToString } from "preact-render-to-string";

// Expose to QuickJS global scope
(globalThis as any).Preact = preact;
(globalThis as any).PreactHooks = hooks;
(globalThis as any).PreactSignals = signals;
(globalThis as any).renderToString = renderToString;
(globalThis as any).h = h;
```

This ensures that `h` and `renderToString` are always available globally in your SSR environment without any setup.

## 5. JIT Compilation & The Sidecar

Salvia uses a "Managed Sidecar" architecture to provide instant feedback during development.

1.  **Rails** starts a background Deno process (`sidecar.ts`).
2.  When you request a page, the **DevServer** middleware intercepts requests for `.js` files.
3.  It asks the **Sidecar** to compile the corresponding `.tsx` file on-the-fly using `esbuild`.
4.  The compiled JS is served to the browser (or used for SSR).

This eliminates the need for a separate `npm run build` or `deno task watch` command. You just run `rails s` or `ruby app.rb`, and Salvia handles the rest.

## 7. The Ultimate Salvia Stack: Salvia + Turbo + Signals

Salvia, Turbo (Drive/Frames/Streams), そして Preact Signals をすべて組み合わせる構成は、**「Ruby の生産性」と「SPA のユーザー体験」を極限まで効率よく両立させる、Salvia アーキテクチャの完成形** と言えます。

これらを組み合わせることで、**「重厚な JavaScript フレームワーク（Next.js等）」を使わずに、それと同等以上のリッチなアプリケーション** を作ることができます。

それぞれの役割と、組み合わせた時の化学反応（メリット）、そして具体的な実例を解説します。

### 1. 各プレイヤーの役割（何ができるか？）

このアーキテクチャでは、**「誰がどこを担当するか」** が明確に分かれています。

#### 🌿 Salvia (The Brain / 脳)

*   **役割:** **「HTML の生成」と「ロジックの実行」**
*   **できること:**
    *   Ruby (Rails) のコントローラーで DB からデータを取得する。
    *   JSX/TSX (Server Components) を高速にレンダリングして HTML を作る。
    *   クライアントに送る JavaScript を最小限（Islands）にする。

#### 🏎️ Turbo (The Transport / 足)

*   **役割:** **「HTML の運搬」と「画面の書き換え」**
*   **Drive (全体遷移):** リンククリックやフォーム送信を横取りし、ページ全体をリロードせずに `<body>` だけを差し替える（SPA 化）。
*   **Frames (部分置換):** 画面の一部（例: モーダルやサイドバー）だけを独立してナビゲーションさせる。
*   **Streams (差分更新):** サーバーからの指示で、特定の要素だけを「追加」「削除」「更新」する（WebSocket やフォームレスポンスで使用）。

#### ⚡️ Preact Signals (The Nerves / 神経)

*   **役割:** **「瞬時の反応」と「状態の共有」**
*   **できること:**
    *   **Micro-Interactivity:** ボタンを押した瞬間の数値更新や、ドラッグ操作など、0.1秒の遅延も許されない UI を動かす。
    *   **Shared State:** Turbo でページが切り替わっても、メモリ上の状態（カートの中身など）を維持し、複数の Island 間で共有する。

### 2. 全部使うとどうなる？（メリット）

これらをフル活用すると、従来の開発における「トレードオフ（あちらを立てればこちらが立たず）」を解消できます。

1.  **「JS を書かない」のに「ヌルヌル動く」**
    *   基本は Ruby で HTML を返すだけ（Salvia）。
    *   でも画面遷移は爆速（Turbo Drive）。
    *   ここぞという場所だけリッチに動く（Signals）。
    *   結果、**開発コストは低いのに、品質は高い** アプリになります。

2.  **「状態管理」の地獄からの解放**
    *   複雑な「サーバーデータとクライアントデータの同期」が不要になります。データは常にサーバー（HTML）が正です。
    *   クライアントで持つべきは「UIの一時的な状態（Signals）」だけになり、バグが激減します。

3.  **「バンドルサイズ」の劇的な削減**
    *   React Router も Redux も Axios も不要です。
    *   必要なのは Preact と Turbo だけ。初期表示速度（LCP）が圧倒的に速くなります。

### 3. 実例: 「リアルタイム・タスク管理ボード」（Trello風）

この構成で作るとどうなるか、具体的なユーザー操作の流れで見てみましょう。

#### 画面構成

*   **ボード画面:** タスクのリスト（To Do, Doing, Done）が並んでいる。
*   **ヘッダー:** 「未完了タスク数」が表示されている。

#### シナリオと技術の連動

| ユーザーの操作 | 裏側の動き | 担当技術 | 解説 |
| :--- | :--- | :--- | :--- |
| **1. ページを開く** | サーバーでタスク一覧の HTML を生成し、表示する。JS はまだ動いていない。 | **Salvia** | 爆速で画面が表示される（SSR）。 |
| **2. タスクを追加する** | フォームから「会議」と入力して Enter。 | **Turbo Drive** | ページリロードせず、裏で POST リクエストを送信。 |
| **(サーバー処理)** | DB にタスクを保存し、**「新しいタスクの HTML だけ」** をレスポンスする。 | **Salvia** | ページ全体を返さないので軽い。 |
| **3. 画面に反映** | レスポンスを受け取り、リストの一番下にタスクを `append` (追記) する。 | **Turbo Streams** | 一瞬でリストが更新される。 |
| **4. 数値が増える** | タスク追加を検知し、ヘッダーの「未完了数」を `+1` する。 | **Signals** | 画面再描画なしで、数字のテキストノードだけ書き換わる。 |
| **5. 詳細を開く** | タスクをクリックすると、画面遷移せずにモーダルで詳細が出る。 | **Turbo Frames** | `src="/tasks/1"` の HTML を部分的に取得して表示。 |
| **6. ドラッグ移動** | タスクを「Doing」から「Done」へドラッグ＆ドロップする。 | **Preact (Islands)** | **ここだけは JS (Signals) が主役。** サーバーを待たずに即座に UI を動かす。 |

#### コードイメージ

**Controller (Ruby):**

```ruby
def create
  task = Task.create(params[:task])
  
  # Turbo Stream で「追加」命令と「HTML」を返す
  render turbo_stream: turbo_stream.append("todo_list", html: ssr("islands/TaskCard", task: task))
end
```

**TaskCard Island (TypeScript + Signals):**

```tsx
// store.ts (状態共有)
export const totalCount = signal(0);

// TaskCard.tsx
export default function TaskCard({ task }) {
  // マウント時にカウントアップ（Signals）
  useEffect(() => { totalCount.value++ }, []);

  return (
    <div class="card" draggable="true">
      {task.title}
    </div>
  );
}
```

**Header Island (TypeScript + Signals):**

```tsx
// Header.tsx
export default function Header() {
  // TaskCard が増減すると、ここも勝手に変わる
  return <div>Remaining: {totalCount}</div>;
}
```

### 結論

この「全部入り」構成は、**Web アプリケーション開発の "Sweet Spot"（最適解）** です。

*   **Salvia** が土台を作り、
*   **Turbo** がそれを運び、
*   **Signals** が彩りを添える。

それぞれが得意なことだけに集中しているため、無駄がなく、非常に強力です。もしこれからアプリを作るなら、迷わずこの「フルセット」で始めることをお勧めします。

## 8. Props vs Signals: 状態管理のパラダイムシフト

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
