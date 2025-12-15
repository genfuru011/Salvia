# Sage Native Deno Integration Implementation Notes

## 概要
Sageのアーキテクチャを刷新し、Rubyをバックエンド（データ処理・ビジネスロジック）、Denoをフロントエンド（レンダリング・アセット配信）に完全に分離する「Sage Native」構成を実装しました。

## アーキテクチャ: "The Dumb Pipe"
Ruby側はHTMLの中身に関知せず、Denoにレンダリングを委譲する「土管」として機能します。

```text
Browser  <-->  [Sage Middleware]  <-->  (HTTP over UDS)  <-->  [Deno Sidecar]
   |                  |                                          |
   |            (Asset Request) --------------------------->  Serve Static/Build
   |                                                             |
   |            (Page Request)                                   |
   |       [Sage Resource] -> [Context] ------------------->  Render HTML (SSR)
```

## 実装詳細

### 1. 通信プロトコル (HTTP over UDS)
*   **Unix Domain Socket (UDS)**: `tmp/sockets/sage_deno.sock` を介して通信。
*   **Protocol**: 標準的なHTTP/1.1を使用。
*   **Libraries**:
    *   Ruby: `async-http`, `io-endpoint` (Falconエコシステム)
    *   Deno: `Deno.serve` (標準ライブラリ)

### 2. Ruby側 (Sage Core)

#### `Sage::Sidecar` (`lib/sage/sidecar.rb`)
*   Denoプロセスのライフサイクル管理（起動、監視、停止）。
*   RPCクライアントの実装。
*   **自動シリアライズ**: `rpc` メソッド内で `params.as_json` を呼び出し、ActiveRecordオブジェクト等を自動的にJSON互換形式に変換してDenoに送信。

#### `Sage::Middleware::AssetProxy` (`lib/sage/middleware/asset_proxy.rb`)
*   `/assets/` で始まるリクエストをDenoにそのまま転送（ストリーミング）。
*   Ruby側でのファイル探索や加工は一切行わない。

#### `Sage::Context` (`lib/sage/context.rb`)
*   `render(page, props)`: Denoに `render_page` RPCを送信。
*   `component(path, props)`: Denoに `render_component` RPCを送信。
*   `turbo_stream(action, target, component_path = nil, html: nil, **props)`: コンポーネントレンダリング結果をTurbo Stream形式でラップして返却。`props` はキーワード引数として受け取る。

### 3. Deno側 (Adapter)

#### `adapter/server.ts`
*   **RPC Server**:
    *   `render_page`: ページコンポーネント (`app/pages/`) をSSRし、HTML全体（`<head>`含む）を生成。
    *   `render_component`: UI部品 (`app/components/`) をSSR。
*   **Asset Server**: `/assets/` リクエストを処理。esbuildを内蔵し、`.tsx` ファイルをオンデマンドで `.js` にコンパイルして配信。
    *   `deno.json` の `imports` を動的に読み込み、バンドルから除外 (`external`) するため、ライブラリ追加時の設定変更は不要。
    *   `npm:` 指定子をブラウザ向けに `https://esm.sh/` に自動変換してImport Mapを注入。
*   **HMR**: 開発モード時にファイル変更を検知し、ブラウザをリロードさせるスクリプトを注入。

#### `adapter/deno.json`
*   Import Mapの管理（`preact`, `@preact/signals`, `@hotwired/turbo` 等）。
*   JSX設定 (`react-jsx`, `preact`)。
*   `esbuild` の依存関係を追加。

### 4. ディレクトリ構造
```text
my_app/
├── adapter/           # Deno Sidecar Implementation
│   ├── server.ts      # Entry point
│   └── deno.json      # Config & Import Map
├── app/
│   ├── pages/         # Full Page Components
│   ├── components/    # Shared UI Components
│   ├── islands/       # Interactive Islands
│   ├── models/        # ActiveRecord Models
│   └── resources/     # Sage Resources (Controllers)
├── config/
├── public/
└── Gemfile
```

## 開発者体験 (DX) の向上
*   **Zero Config JSON**: ユーザーは `render "Page", user: user` と書くだけ。`as_json` が自動適用されるため、シリアライザの明示的な呼び出しは不要。
*   **APIレス**: フロントエンドのためのAPIエンドポイントを設計する必要がなく、RailsのViewを書く感覚でReact/Preactコンポーネントを利用可能。

## Turbo Strategy (Sage流 Turboの扱い方)

Sageでは、SPAのような部分更新をTurbo Streamsで実現します。

### 1. View (Deno)
更新対象の要素にユニークな `id` を付与します。`<turbo-frame>` は必須ではなく、通常の `div` でも動作します。フォームには特別な `data-turbo` 属性は不要です。

```tsx
// app/components/TodoItem.tsx
export default function TodoItem({ todo }) {
  return (
    <div id={`todo_${todo.id}`}>
      <form action={`/todos/${todo.id}/toggle`} method="post">
        <button>Toggle</button>
      </form>
    </div>
  );
}
```

### 2. Controller (Ruby)
処理完了後、`ctx.turbo_stream` を返します。

```ruby
post "/:id/toggle" do |ctx, id|
  todo = Todo.find(id)
  # ... update logic ...
  
  # Denoに "components/TodoItem" のレンダリングを依頼し、
  # 結果のHTMLで id="todo_#{id}" の要素を置換する命令をブラウザに送る
  ctx.turbo_stream("replace", "todo_#{id}", "components/TodoItem", todo: todo)
end
```

### 3. 仕組み
1.  ブラウザでフォーム送信（Turboがインターセプト）。
2.  Rubyが処理し、`<turbo-stream action="replace" target="...">` を含むHTMLを返す。
3.  Turboがレスポンスを受け取り、指定された `target` IDのDOM要素を更新する。
