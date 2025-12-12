# Salviaの知恵: 真のHTMLファーストのアーキテクチャ

## 1. Sageへの道 (ビジョン)

Salviaは単なるビューエンジンではありません。それは、"真のHTMLファースト"時代のためにゼロから設計された将来のRuby MVCフレームワークである **Sage** のための基盤技術です。

Sageが開発中である間、Salviaはこの未来的なアーキテクチャを今日の **Ruby on Rails** にもたらします。これにより、Rails開発者はRubyエコシステムを離れることなく、ERB/Slimを捨て、モダンなコンポーネントベースのフロントエンドワークフローを採用することができます。

## 2. アーキテクチャ: Rails + JSX

Salviaは、Ruby (Controllers & Models) の堅牢なバックエンドロジックを維持しながら、従来のRails Viewレイヤーを完全にJSX/TSXに置き換えます。

**アーキテクチャの比較:**

| 機能 | Rails (従来) | Next.js (App Router) | Salvia (Rails + JSX) |
| :--- | :--- | :--- | :--- |
| **ルーティング** | Ruby (routes.rb) | ファイルシステム (JS) | Ruby (routes.rb) |
| **データ取得** | Ruby (Controller) | JS (Server Components) | Ruby (Controller) |
| **ビューロジック** | ERB (Ruby) | JSX (React) | **JSX (Preact/React)** |
| **インタラクティブ** | Stimulus / Turbo | React (Hydration) | **Islands (Hydration)** |
| **ビルドステップ** | Asset Pipeline / Vite | Webpack / Turbopack | **No Build (JIT via Deno)** |

Salviaでは、Railsコントローラーがデータベース (ActiveRecord) からデータを取得し、それを直接 **Server Component (Page)** に渡します。このコンポーネントはサーバー上でHTMLにレンダリング (SSR) され、ブラウザに送信されます。

*   **デフォルトでJSゼロ**: 静的コンテンツは単なるHTMLです。
*   **Islandsアーキテクチャ**: インタラクティブな部分 (Islands) だけがJavaScriptでハイドレーションされます。

## 3. ディレクトリ構造 ("Salvia" ディレクトリ)

フロントエンドの関心事をRubyバックエンドから分離するために、Salviaはプロジェクトルートに `salvia/` ディレクトリを導入します。

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

## 4. ゼロコンフィグアーキテクチャ (複雑性の内包)

Salvia v0.2.0は、Next.jsやFreshに触発された **ゼロコンフィグ** 哲学を採用しています。

### 設定の内包化
以前は露出していた `deno.json` や `vendor_setup.ts` などの設定ファイルは、現在Salvia gem内部に内包されています。これは以下のことを意味します：

1.  **ボイラープレートなし**: 複雑なビルド設定やインポートマップを管理する必要はありません。
2.  **Preactのみ**: Salviaは意見を持っており、最大のパフォーマンスと互換性のためにPreact + Signalsアーキテクチャを厳格に強制します。
3.  **自動インポートマップ**: Salviaは内部設定に基づいてブラウザ用のインポートマップを自動的に生成し、`preact`、`preact/hooks`、`@preact/signals` がすぐに動作することを保証します。

### 内部での動作

`vendor_setup.ts` などの複雑な設定ファイルは隠蔽されていますが、`deno.json` はプロジェクトルートに公開されています。これにより、依存関係を簡単に管理できます：

1.  **ブラウザ (クライアントサイド)**: HTML内に生成されたインポートマップ経由。
2.  **SSR (サーバーサイド)**: 内部の `deno.json` を使用したDeno/QuickJSモジュール解決経由。
3.  **型チェック**: DenoのネイティブTypeScriptサポート経由。

**主要な概念:**

*   **Preactファースト**: Salviaは、その軽量性と強力なSignalsアーキテクチャのためにPreact上に構築されています。
*   **`npm:` 指定子**: Denoはこれを使用してnpmからパッケージを取得します。Salviaは、ブラウザ用のインポートマップを生成する際に、これらを自動的に `https://esm.sh/...` URLに変換します。

### `vendor_setup.ts` (ブリッジ)

ESMモジュールをQuickJS SSRエンジンで利用可能にするために、Salviaは `vendor_setup.ts` という内部ブリッジファイルを使用します。このファイルはPreactとSignalsをインポートし、QuickJSのグローバルスコープに公開します。

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

これにより、`h` と `renderToString` が設定なしでSSR環境で常にグローバルに利用可能になります。

## 5. JITコンパイル & サイドカー

Salviaは、開発中に即時のフィードバックを提供するために "Managed Sidecar" アーキテクチャを使用します。

1.  **Rails** がバックグラウンドのDenoプロセス (`sidecar.ts`) を開始します。
2.  ページをリクエストすると、**DevServer** ミドルウェアが `.js` ファイルへのリクエストをインターセプトします。
3.  それは **Sidecar** に、対応する `.tsx` ファイルを `esbuild` を使用してオンザフライでコンパイルするように依頼します。
4.  コンパイルされたJSがブラウザに提供されます (またはSSRに使用されます)。

これにより、別の `npm run build` や `deno task watch` コマンドが不要になります。単に `rails s` や `ruby app.rb` を実行するだけで、Salviaが残りを処理します。

## 7. 究極のSalviaスタック: Salvia + Turbo + Signals

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

## 8. ステートフリー開発 (State-free Development)

「ステートフリー開発」とは、**「開発者が『状態管理』として意識してコーディングしなければならない領域が、極限までゼロに近づく」** という体験を指します。

Salvia + Turbo + Signals の組み合わせにより、Webアプリ開発で我々を苦しめる「3つの状態」は以下のように処理（または消滅）されます。

### 1. どこへ消えた？ 「3つのState」

#### ① Server State（データそのもの）
* **これまで (SPA):** API から JSON を fetch し、Redux 等で管理する。
* **これからは (Salvia):** **サーバーにあるデータが「正」であり、HTML がそのスナップショット。** クライアント側でデータを保持・同期する必要がない。
    * **→ State 消滅 (Server Components が解決)**

#### ② URL/Navigation State（今どこにいるか）
* **これまで (SPA):** `react-router` 等で現在のパスやパラメータを JS で監視する。
* **これからは (Turbo Drive):** **URL こそが状態。** リンクを踏めば Turbo が勝手に次の HTML を取ってきて書き換える。
    * **→ State 消滅 (Turbo が解決)**

#### ③ UI State（入力中、開閉、一時的な変化）
* **これまで (React):** `useState` で管理し、バケツリレーや Context API で共有する。
* **これからは (Signals):** **必要な場所で `signal()` を定義して、`.value` を書き換えるだけ。** コンポーネントの再レンダリングすら発生しない。
    * **→ State 管理が「ただの変数代入」になる。**

### 2. 「ステートフリー」の実感： ショッピングカートの例

「商品をカートに入れる」という動作で比較すると、その差は歴然です。

#### 😫 従来の SPA (Stateful)
1.  Action Creator を定義 (`addToCart`)。
2.  Reducer で状態更新ロジックを書く (`state.items.push(...)`)。
3.  コンポーネントで `useDispatch` と `useSelector` する。
4.  ボタンを押したら dispatch。
5.  非同期で API を叩き、失敗したらロールバックする処理を書く。

#### 😌 Salvia + Turbo + Signals (State-free like)

**パターンA: Turbo Streams (完全ステートレス)**
1.  **JS:** なし。
2.  **View:** `<form action="/cart" method="post">` を書く。
3.  **Server:** カートに追加し、**「更新されたヘッダーのHTML」** をレスポンスする。
4.  **Turbo:** ヘッダーを書き換える。
    * **→ JS の状態管理ゼロ。**

**パターンB: Signals (楽観的UI)**
1.  **Global Signal:** `export const count = signal(0);`
2.  **Button:** `onClick={() => count.value++}` (見た目を即座に更新)
3.  **Background:** 裏で `fetch("/cart", ...)` を投げる（結果は気にしない、または失敗時だけ戻す）。
    * **→ 状態管理は `count.value++` の 1行だけ。**

### 3. このアーキテクチャの正体

これは **「Web 本来の姿（Stateless HTTP）」への回帰** です。

Salvia (Turbo + Signals) は、**「基本はステートレス（サーバー主導）に戻りつつ、どうしてもリッチにしたい 10% の部分だけ、Signals という『現代最強の飛び道具』を使う」** というアプローチです。

* **面倒なこと（データ同期、ルーティング）** → **やらない（サーバーとTurboに任せる）。**
* **楽しいこと（アニメーション、インタラクション）** → **Signals でやる。**

これが、**「ステートフリー開発」** と呼ぶにふさわしい体験です。

## 9. Props vs Signals: 状態管理のパラダイムシフト

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
