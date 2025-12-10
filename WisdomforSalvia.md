# Wisdom for Salvia: The True HTML First Architecture

Salvia は、Ruby の堅牢なバックエンドと、モダンなフロントエンド（JSX/TSX）の表現力を融合させた、新しい「HTML First」アーキテクチャを提案します。
これは単なる SSR エンジンではなく、Web アプリケーション開発における「View 層の再定義」です。

---

## 1. Core Concepts & Architecture

### The "True HTML First" Flow

Salvia のアーキテクチャは、**「サーバーで完成された HTML を返し、必要な部分だけをクライアントで活性化する」** という哲学に基づいています。

```mermaid
sequenceDiagram
    participant Browser
    participant Turbo as Turbo Drive
    participant Rails as Rails/Sinatra
    participant Salvia as Salvia (QuickJS)
    
    Browser->>Rails: GET /posts/1
    Note right of Browser: 通常のHTTPリクエスト
    
    Rails->>Rails: DBからデータ取得 (@post)
    Rails->>Salvia: Component名 + Props (@post)
    
    rect rgb(240, 248, 255)
        Note over Salvia: SSR Process
        Salvia->>Salvia: JSXをHTMLにレンダリング
        Salvia->>Salvia: Server Componentsは静的HTML化
        Salvia->>Salvia: IslandsはHTML + Hydration Script生成
    end
    
    Salvia-->>Rails: 完成されたHTML文字列
    Rails-->>Browser: HTML Response
    
    Note over Browser: 初期表示完了 (FCP/LCPが高速)
    
    Browser->>Browser: IslandsのみHydrate (JS実行)
    Note over Browser: インタラクティブ機能が有効化
    
    Browser->>Turbo: リンククリック (/posts/2)
    Turbo->>Rails: fetch("/posts/2")
    Rails-->>Turbo: HTML Response
    Turbo->>Browser: bodyタグの中身を置換
    Note over Browser: 画面遷移 (SPAのような体験)
```

---

## 2. Detailed Comparisons

### vs Next.js (Node.js Backend / BFF)

Next.js は素晴らしいフレームワークですが、Rubyist にとっては「別の言語・別のサーバー」を管理するコストが発生します。

| 特徴 | Next.js (App Router) | Salvia (on Ruby) |
| :--- | :--- | :--- |
| **主要言語** | TypeScript / JavaScript | **Ruby** (Backend) + TSX (View) |
| **インフラ** | Node.js サーバーが必要 | **既存の Ruby サーバー** (Puma/Unicorn) 内で完結 |
| **データ取得** | API (REST/GraphQL) or Server Actions | **Ruby メソッド呼び出し** (ActiveRecord 等) |
| **状態管理** | Client Component 間で複雑になりがち | **URL ベース** (Turbo Drive) + 局所的な State |
| **ビルド** | Webpack/Turbopack (複雑) | **esbuild** (Deno経由で高速・シンプル) |

**Salvia の勝ち筋**:
Ruby のエコシステム（ActiveRecord, RSpec, Sidekiq）をそのまま使いながら、View だけをモダンにできます。「API を作る手間」がゼロになります。

### vs Rails + React (SPA / API Mode)

Rails を API モードにして、フロントエンドを React SPA で作る構成です。

| 特徴 | Rails API + React SPA | Salvia |
| :--- | :--- | :--- |
| **初期表示** | 遅い (JS バンドルロード -> API フェッチ -> レンダリング) | **爆速** (サーバーから HTML が即座に返る) |
| **SEO** | 弱い (クローラー対策が必要) | **最強** (完全な HTML が返る) |
| **開発フロー** | Rails API 定義 -> React 型定義 -> fetch 実装 | **Controller で Props を渡すだけ** |
| **認証** | JWT / Cookie 管理が複雑 | **Rails の Session / Devise** がそのまま使える |

**Salvia の勝ち筋**:
「ローディングスピナー」を見せる必要がありません。データは最初からそこにあります。

---

## 3. Deep Dive: Key Technologies

### A. JSX View & ERBless (ERB からの脱却)

ERB は強力ですが、複雑な UI を作ると「ヘルパー地獄」や「jQuery との格闘」になりがちです。JSX は「UI を関数として合成する」ための最高の構文です。

**Old Way (ERB):**
```erb
<!-- app/views/posts/show.html.erb -->
<div class="post">
  <h1><%= @post.title %></h1>
  <%= render partial: "comments/list", locals: { comments: @post.comments } %>
  <!-- JSで動くボタンを作るために data 属性や script タグが必要... -->
  <button onclick="alert('Like!')">Like</button>
</div>
```

**Salvia Way (JSX):**
```tsx
// app/components/PostDetail.tsx
export default function PostDetail({ post }: { post: Post }) {
  return (
    <div class="post">
      <h1 class="text-2xl font-bold">{post.title}</h1>
      {/* コンポーネントとして自然にネスト可能 */}
      <CommentList comments={post.comments} />
      
      {/* インタラクティブな部分は Island として分離 */}
      <LikeButton postId={post.id} />
    </div>
  );
}
```
*   **型安全性**: `post.title` が存在するか、型定義で保証されます。
*   **コンポーネント化**: `CommentList` や `LikeButton` を import して使うだけ。

### B. JSON API-less (No More "API Glue")

Salvia では、データを JSON にシリアライズして API エンドポイントを作る必要がありません。

**Old Way (React SPA):**
1.  Rails: `render json: @post` (Serializer 定義)
2.  React: `useEffect(() => fetch('/api/posts/1')...)`
3.  React: `if (loading) return <Spinner />`
4.  React: `<div>{data.title}</div>`

**Salvia Way:**
1.  Rails: `render_island "PostDetail", props: { post: @post }`
2.  Salvia: HTML 生成
3.  Browser: 表示完了

**「API の糊付けコード (Glue Code)」が消滅します。**

### C. Server Components vs Islands

Salvia はデフォルトで **Server Components** です。つまり、クライアントに JS を送りません。

*   **Server Components (`app/pages/`)**:
    *   ページ全体のレイアウトや静的なコンテンツ（ヘッダー、フッター、記事本文）。
    *   クライアントバンドルには含まれません（JSサイズ **0 bytes**）。
    *   `useState` や `useEffect` は使えません（サーバーで1回実行されるだけ）。

*   **Islands (`app/islands/`)**:
    *   動的な部分（いいねボタン、ドロップダウン、カルーセル）。
    *   このディレクトリ内のファイルだけがクライアントで Hydrate されます。
    *   `useState` や `onClick` が使えます。

*   **Components (`app/components/`)**:
    *   再利用可能な UI 部品（ボタン、カード、レイアウトなど）。
    *   `pages` や `islands` から `import` して使用します。
    *   これ自体はエントリーポイントになりません（どこから使われるかによって、サーバー側のみか、クライアント側にも含まれるかが決まります）。

**例: 記事ページ**
```tsx
export default function ArticlePage({ article }) {
  return (
    <Layout>
      {/* Server Component: 静的HTMLのみ。JSなし。高速。 */}
      <ArticleContent body={article.body} />
      
      {/* Island: ここだけJSがロードされ、動的に動く */}
      <CommentSection articleId={article.id} />
    </Layout>
  );
}
```

### D. Turbo Drive Integration

Salvia が生成した HTML は、Turbo Drive によって SPA のように遷移します。

1.  ユーザーがリンクをクリック。
2.  Turbo が `fetch` で次のページの HTML を取得。
3.  現在の `<body>` を新しい HTML で置換。
4.  `<head>` 内のスクリプト（Islands のバンドルなど）をマージ。

これにより、**「React Router などのクライアントサイドルーター」が不要** になります。ルーティングは全て Rails/Sinatra 側（`config/routes.rb`）で管理します。

---

### E. Import Map Strategy: deno.json & Browser Import Map

Salvia は、ビルド時と実行時のパフォーマンスを両立させるために、2つの異なるインポート戦略を組み合わせています。

#### 1. Build Time (`deno.json`)
**役割**: サーバーサイドレンダリング（SSR）のビルド時に Deno が使用します。
- **設定**: `salvia/deno.json` の `imports` セクションにライブラリを定義します。
- **動作**: ここで定義されたライブラリは、サーバー上で HTML を生成するために使われます。

#### 2. Runtime (`<script type="importmap">`)
**役割**: ブラウザ（クライアントサイド）が実行時に使用します。
- **設定**: `salvia_import_map` ヘルパーが、`salvia/deno.json` の `imports` を自動的に読み込んで出力します。
- **メリット**:
    - **一元管理**: `deno.json` を編集するだけで、ビルド環境とブラウザ環境の両方に設定が反映されます。
    - **重複排除**: 各 Island ファイルにライブラリのコードを含める必要がなくなります。
    - **キャッシュ**: ブラウザはライブラリをアプリケーションコードとは独立してキャッシュできます。

#### カスタマイズ（ライブラリの追加）
使用するフレームワークやライブラリが増えた場合は、`salvia/deno.json` の `imports` に追加するだけでOKです。

```json
// salvia/deno.json
{
  "imports": {
    "preact": "https://esm.sh/preact@10.19.6",
    "uuid": "https://esm.sh/uuid@9.0.1"
  }
}
```

これにより、`salvia_import_map` ヘルパーが自動的にこの設定を読み込み、ブラウザに出力します。

### F. The Road to ERBless (True HTML First)

現在、Salvia は多くの場合 ERB/Slim テンプレートの中で `<%= island ... %>` のように使われています。しかし、Salvia の究極の目標は **"ERBless"** —— つまり、Ruby の View 層（ERB）を完全に排除することです。

#### コンセプト: "Ruby for Logic, JSX for View"
Next.js の App Router (React Server Components) に非常に近いアーキテクチャですが、「ルーティングとデータ取得は Ruby (Rails/Sinatra) が担当し、View 層だけを JSX が担当する」という点が異なります。

**現在のハイブリッド構成:**
1. Controller -> `views/posts/index.html.erb`
2. ERB -> `<%= island 'PostList', posts: @posts %>`
3. Salvia -> PostList の HTML を生成して埋め込む

**ERBless (完全版):**
1. Controller -> `render_salvia 'pages/PostsIndex', props: { posts: @posts }`
2. Salvia -> `<html>`, `<head>`, `<body>` を含むドキュメント全体を生成。

#### Next.js App Router との比較

| 機能 | Next.js (App Router) | Salvia (ERBless) |
| :--- | :--- | :--- |
| **Routing** | File-system based (`app/page.tsx`) | **Ruby Routes** (`config/routes.rb`) |
| **Data Fetching** | `async` Server Component | **Ruby Controller** (`@posts = Post.all`) |
| **Server Components** | Default (React) | **Default** (Preact via QuickJS) |
| **Client Interactivity** | `"use client"` directive | **Islands Architecture** (`app/islands/`) |
| **Server Actions** | `"use server"` functions | **Standard HTTP Form POST** |

**Salvia のアプローチの利点:**
1.  **既存資産の活用**: 複雑なビジネスロジック、認証、DB操作は、成熟した Ruby エコシステム（ActiveRecord, Devise, Pundit）をそのまま使えます。
2.  **明確な分離**: 「データを用意する人（Ruby）」と「表示する人（JSX）」が明確に分かれます。コンポーネントの中に SQL や API コールが混ざりません。
3.  **学習コスト**: フロントエンドエンジニアは JSX だけ書けばよく、バックエンドエンジニアは Ruby だけ書けばよいです。繋ぎこみは `props` だけです。

#### 実現方法
`app/pages/` ディレクトリにページ全体のコンポーネントを配置し、コントローラーから直接それを呼び出すことで、今すぐこのアーキテクチャを実現可能です。`application.html.erb` すらも不要になり、すべてが JSX で完結する世界です。

---

### G. Why "use server" is Unnecessary

Next.js などのフレームワークでは、クライアントコンポーネントからサーバー側の関数を直接呼び出すために **Server Actions (`"use server"`)** という機能があります。これは実質的に RPC (Remote Procedure Call) です。

**Salvia では、この概念は不要（または既に存在している）です。**

1.  **"Action" は標準の Controller:**
    Salvia は Rails/Sinatra の上に構築されているため、最強の "Server Action" システムである **HTTP Controller** が既に存在します。
2.  **HTML Form こそが RPC:**
    JS の関数をボタンに紐付ける代わりに、標準的な HTML フォームを使います。
    ```tsx
    // Salvia View (JSX)
    <form action="/posts" method="post">
      <input name="title" class="border" />
      <button type="submit">Create</button>
    </form>
    ```
3.  **No Magic:**
    送信ボタンを押すと、標準の POST リクエストが `PostsController#create` に飛びます。Rails が DB を更新し、リダイレクトまたは再レンダリングを行います。Turbo Drive がその遷移を滑らかに処理します。
4.  **責務の分離:**
    ロジックは Ruby (Controller/Model) に、表示は JSX (View) に。UI コンポーネントの中にデータベース操作ロジックを混ぜる必要はありません。

---

## 4. Conclusion: The "Salvia" Experience

Salvia は、**「Ruby で開発する楽しさ」** を損なうことなく、**「現代的なフロントエンドの UX」** を手に入れるための武器です。

*   **Rubyist にとって**: 慣れ親しんだ Controller と Model がそのまま使えます。View だけが強力になります。
*   **Frontend Engineer にとって**: 好きな JSX/TSX と Tailwind CSS で UI を構築できます。API 待ちの時間がなくなります。
*   **User にとって**: ページが爆速で表示され、サクサク動きます。

**"Write Ruby, Render JSX, Deliver HTML."**
これが Salvia の真髄です。
