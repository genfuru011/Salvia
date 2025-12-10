# 検証・改善タスクメモ

## 1. スレッドセーフ性とログの競合問題 (重要)
現在の `Salvia::SSR::QuickJS` 実装では、QuickJS VM 自体は `Thread.current` を使用してスレッドローカルに保持されていますが、**ログを格納する `@js_logs` インスタンス変数が全スレッドで共有されています。**

*   **問題点**: 
    *   複数のリクエストが同時に処理される際、あるリクエストのログを別のリクエストが `flush_logs` で取得してしまう可能性があります。
    *   `Array#<<` 操作の競合により、ログが消失する可能性があります。
*   **検証・修正案**:
    *   ログバッファも `Thread.current` に持たせるか、`render` メソッドの戻り値の一部としてログを返す設計への変更を検討する必要があります。

## 2. パフォーマンスとメモリ消費
*   **VM作成コスト**: スレッドごとに `Quickjs::VM.new` とバンドルの `eval` が実行されます。スレッド数が多い環境（Pumaなど）でのメモリ消費量と、スレッド初回利用時のレイテンシを検証する必要があります。
*   **ベンチマーク**: 
    *   同時接続数が多い場合のレスポンスタイム。
    *   長時間稼働時のメモリリークの有無（QuickJS VMのGC挙動）。

## 3. 他のRubyフレームワーク対応
*   **Roda / Hanami**: 現在は Rails と Sinatra での動作確認のみです。
    *   Rack ミドルウェアとしての統合や、各フレームワーク固有のヘルパーとの連携を検証する必要があります。
    *   特に Hanami 2.x 系との統合は、モダンなRuby開発において需要があります。

## 4. フロントエンドフレームワークの多様性
*   **React / Vue / Svelte / Solid**: 現在は Preact がデフォルトです。
    *   `deno.json` のインポートマップやビルドスクリプト (`build.ts`) が、他のフレームワークのSSRライブラリ（`react-dom/server` など）と正しく連携できるか検証が必要です。
    *   ハイドレーションの仕組みがフレームワークごとに異なるため、`islands.js` の汎用性を高める必要があるかもしれません。

### 4. JIT Architecture & Caching Strategy (Future Roadmap)

ユーザーから提案された「Ruby-driven On-demand Transpilation」アーキテクチャについての分析。

#### 概要
現状の「事前ビルド (Deno)」から、「JITコンパイル (Ruby + esbuild)」への移行案。
`rails s` だけで完結し、変更検知 -> 高速トランスパイル -> QuickJS実行 -> HTMLキャッシュ というフローを目指す。

#### 評価: ✅ 非常に正しい方向性
Salviaの目指す「DXの向上（ビルドコマンド不要）」と「パフォーマンス（HTML First）」に完全に合致する。

#### 現状 (v0.1.0) との比較

**Current Implementation Detail:**
現状の `salvia/build.ts` は、ビルド時に `import * as esbuild from "https://deno.land/x/esbuild@v0.24.2/mod.js";` を実行し、Deno 上でバンドルを行っています。

**Current Implementation Detail:**
現状の `salvia/build.ts` は、ビルド時に `import * as esbuild from "https://deno.land/x/esbuild@v0.24.2/mod.js";` を実行し、Deno 上でバンドルを行っています。

| 機能 | 現状 (Current) | 提案 (Future JIT) |
| :--- | :--- | :--- |
| **Build** | `deno task build` (事前ビルド) | `esbuild` via Ruby (オンデマンド) |
| **Watcher** | `deno task watch` (別プロセス) | Rubyがリクエスト時に検知 (不要) |
| **Transpiler** | Deno (SWC/esbuild) | esbuild (Go binary) |
| **Dependencies** | `deno.json` (URL Imports) | **課題**: esbuildでのURL解決 |
| **Caching** | なし (毎回レンダリング) | **HTML Fragment Caching** (Rails.cache) |
| **SSR Engine** | QuickJS (VM永続化済み) | QuickJS (Bytecode Cache + VM) |

#### 技術的課題: 外部ライブラリの解決 (URL Imports)
Denoは `https://esm.sh/react` などをネイティブに解決してバンドルできるが、標準の `esbuild` はローカルファイル (`node_modules` 等) を前提としていることが多い。
SSRバンドルを作る際、外部ライブラリをどう解決するかが最大の壁。

**解決案:**
1. **Hybrid**: 開発時はDenoを裏で叩く（現状維持だが隠蔽する）。
2. **Download**: `bin/importmap` のように `vendor/` にダウンロードして esbuild に食わせる。
3. **Plugins**: esbuild の http-import プラグイン的な機構を Ruby で再現する。

#### 推奨ステップ
1. **Level 1: HTML Fragment Caching** (今すぐできる)
   - `Salvia::Helpers::Island` に `Rails.cache` を組み込む。
   - これだけで本番パフォーマンスは劇的に向上する。

2. **Level 2: JIT Transpilation** (難易度高)
   - `esbuild` gem の導入。
   - Deno依存からの脱却（またはDenoを隠蔽）。

このアーキテクチャは **Salvia v0.2.0 以降のコア目標** とすべき。

## 6. エラーハンドリングの強化
*   **ハイドレーション不整合**: SSRされたHTMLとクライアントサイドのJSが一致しない場合の挙動とリカバリ。
*   **タイムアウト**: JS実行が無限ループに陥った場合の強制終了メカニズム（QuickJSの機能で制限可能か検証）。

## 7. コンポーネントディレクトリと独立性 (User Feedback)
*   **`components/` の利用**:
    *   `app/components/Button.jsx` を作成し、`islands/Counter.jsx` から import して利用することは**可能**です（esbuildが依存関係を解決してバンドルします）。
    *   これにより、UIパーツ（ボタン、カードなど）を再利用可能なコンポーネントとして定義できます。
*   **独立した利用 (Freshとの比較)**:
    *   現状、Ruby側から `<%= island "Name" %>` で呼び出せるのは `islands/` ディレクトリ直下のファイルのみです。
    *   `components/` 内のファイルを直接レンダリングしたい場合は、それを `islands/` に置くか、将来的に「Static Component（JSなしSSR）」としてのサポートを追加する必要があります。
    *   Fresh同様、"Island" として定義されたものだけが、独立したエントリーポイント（ハイドレーション対象）として機能します。

## 8. Server Components vs RSC (React Server Components)
*   **Salviaの `app/components/` (Server Components)**:
    *   **純粋なサーバーサイドレンダリング**: サーバーでJSXをHTML文字列に変換して返すだけです。
    *   **No Client JS**: クライアントにはHTMLとして届くため、JavaScriptは一切配信されず、ハイドレーションもされません（Islandsからインポートされない限り）。
    *   **用途**: ボタン、レイアウト、静的なUIパーツ。従来のERB/Slimの代わりとしてJSXを使うイメージです。
    *   **RSCとの違い**: React Server Components (RSC) は、サーバーで実行されつつ、クライアントコンポーネントと連携し、状態を保持したまま部分更新（ストリーミングやシリアライズ）を行う複雑な仕組みです。Salviaのこれは単なる「JSXテンプレートエンジン」としての利用に近いです。

## 9. View層の代替としての可能性 (ERB/Slimレス)
ユーザーからの指摘通り、Salviaのコンポーネント(SSR)を全面的に採用することで、ERBやSlimの記述を最小限に抑えることが理論上可能です。

*   **極端な構成**:
    *   Rails/SinatraのView (ERB) は `layout.erb` と、各アクションで `<%= island 'PageRoot', props %>` を呼び出すだけの薄いラッパーになる。
    *   UIロジック、条件分岐、ループなどは全て JSX (Preact) 側で完結する。
*   **具体的な開発フロー**:
    1.  RubyのControllerでデータを取得 (`@users = User.all`)。
    2.  View (ERB) は `<%= salvia_island "UsersPage", users: @users %>` の1行のみ。
    3.  `app/islands/UsersPage.jsx` (または `components/`) でリスト表示やレイアウトを全て記述。
*   **メリット**:
    *   フロントエンド(JSX)とバックエンド(Ruby)の境界が明確になる。
    *   Reactエコシステムの恩恵（コンポーネントライブラリなど）をフルに受けられる。
*   **RSCとの違い**:
    *   Salviaはあくまで「文字列としてのHTML」をRubyから返しているだけなので、クライアントサイドでのSPA遷移（ページ遷移なしでの書き換え）は自動では行われない（Turbo Driveなどを併用すれば可能）。
    *   データフェッチはRubyのControllerで行い、Propsとして渡す必要がある（RSCのようにコンポーネント内でDBアクセスはできない）。

## 10. 🚀 真のHTML Firstへの道: Turbo Drive + Full SSR JSX
ユーザーの指摘通り、これは「サーバーサイドが主導する真のHTML First」アーキテクチャに非常に近い。

1.  **サーバーでJSXをレンダリング (SSR)**:
    *   ERB/Slimの代わりに、表現力豊かなJSX (TSX) をテンプレートとして使用。
    *   コンポーネント指向でUIを構築できる。
    *   出力は純粋なHTML。

2.  **Turbo DriveでSPA風の遷移**:
    *   ページ遷移はTurbo Driveがインターセプトし、bodyを置換。
    *   ブラウザはHTMLを受け取って表示するだけ。JSの初期化コストが極小。

3.  **必要な部分だけIsland**:
    *   インタラクティブな部分だけ `islands/` に配置してHydration。
    *   それ以外の `components/` はただのHTML文字列になるため、クライアントサイドのJSバンドルサイズを圧迫しない。

**結論**:
Salviaは単なる「RailsでReactを使うツール」ではなく、**「JSXをサーバーサイドテンプレートエンジンとして使い、Turboで配信する」** という新しいRailsフロントエンドの標準形になり得るポテンシャルがある。

- **検証事項**:
  - Turbo Driveのキャッシュ復元時にIslands（Preact）のハイドレーションが正しく再実行されるか？（`turbo:load` イベントでの再マウント処理が必要かも）

## 11. 結論 (2025-12-10)
現状のアーキテクチャ（Islands Architecture）で進める方針で確定。
- **Islands (`app/islands/`)**: クライアントサイドでのハイドレーションが必要なコンポーネント（インタラクティブなボタン、カウンターなど）。
- **Components (`app/components/`)**: Islandsからインポートして使う、またはSSRのみで使う静的なUIパーツ。これらは単体ではハイドレーションされないが、Islandsの一部として組み込まれれば機能する。

Freshのように「Islandsディレクトリにあるものだけがハイドレーションのエントリーポイントになる」という仕様は、バンドルサイズを抑え、明示的な境界を作る上で理にかなっているため、このまま維持する。

## 12. Deno Integration Strategy: Standard IO vs Managed Sidecar

"Vite-like" な爆速開発体験を実現するために、Deno をどう統合すべきか？

| Feature | A. Standard IO (CLI Filter) | B. Managed Sidecar (Worker) |
| :--- | :--- | :--- |
| **仕組み** | リクエスト毎に `deno run` を起動し、標準入力でコードを渡し、標準出力で受け取る。 | Rails起動時に `deno run --server` を裏で立ち上げ、Unix Socket/HTTP で通信し続ける。 |
| **パフォーマンス** | ⚠️ **低〜中**: 毎回 Deno VM の起動とモジュールロード(esbuild等)が発生。数百msのオーバーヘッド。 | 🚀 **高**: VM起動は最初だけ。esbuild インスタンスもメモリに常駐可能。ミリ秒単位の応答。 |
| **実装難易度** | ✅ **低**: ステートレス。プロセス管理不要。`Open3.capture3` だけで実装可能。 | ⚠️ **高**: プロセスの起動・停止・再起動・ゾンビ化防止・ポート競合管理が必要。 |
| **キャッシュ** | ディスクキャッシュ (Deno cache) のみ。 | メモリキャッシュ (esbuild rebuild context) が利用可能。 |
| **安定性** | 非常に高い。1回失敗しても次はクリーンな状態で走る。 | プロセスがクラッシュした場合の復帰処理が必要。 |

### 推奨アプローチ: "Managed Sidecar" (最初から最適解を目指す)

**Phase 1: Managed Sidecar (Persistent Worker)**
Standard IO (PoC) をスキップし、最初から **Managed Sidecar** パターンで実装します。
理由:
1. **圧倒的なパフォーマンス**: esbuild のリビルドコンテキストをメモリに保持できるため、変更検知から再ビルドまでがミリ秒単位で完了します。Standard IO では毎回起動コストがかかり、Viteのような体験には届きません。
2. **エコシステムのフル活用**: 常駐プロセスであれば、`deno check` (型チェック) や `deno fmt` (整形) をバックグラウンドで効率的に実行できます。
3. **実装の二度手間を回避**: Standard IO から移行する場合、通信部分のロジックを書き直す必要があります。最初からソケット通信/IPCを前提に設計する方が効率的です。

## 13. Deno Ecosystem: The "Dream Features" (Why Worker is the Future)

Deno Worker (Managed Sidecar) を常駐させておくと、単なるトランスパイル（JIT）以外にも、Deno のエコシステムを使って以下のような「リッチな機能」を Salvia に追加できます。

### A. フォーマッターとリンター (Deno fmt/lint)
Ruby 側から「この TSX、整形して」と投げるだけで、`deno fmt` の高速なフォーマッターを使えます。Rails の View (TSX) が常に綺麗な状態に保たれます。

### B. 型チェック (TypeScript Check)
開発中に裏で `deno check` を走らせておき、Rails のログに「⚠️ Home.tsx の 15行目、型が合ってないよ」と警告を出すことができます。Rubyist にとって面倒な `tsc` コマンド設定なしで、型安全性が手に入ります。

### C. JSX の最適化 (Fresh の知見)
Fresh フレームワークが持っている「アイランドの自動検知」や「不要な JS の削除（Tree Shaking）」などの高度な最適化ロジックを、そのまま Deno 側のコードとして流用できます。

### 結論
**「Deno Worker (常駐)」一択です。**

*   **パフォーマンス**: プロセス起動コストゼロ、インクリメンタルビルド可。
*   **エコシステム**: Deno の全能力（fmt, lint, check, http imports）を、Ruby から API 感覚で呼び出せるようになります。

これは単なる「コンパイラ」ではなく、**「Ruby のための、Deno 製の高機能なフロントエンド・サーバー」** を手に入れることを意味します。これが Salvia の最強の武器になります。

## 14. 実装ロードマップ (Revised)

## 15. Verification Results (Rails API Mode)

Verified Salvia with a new Rails API application (`examples/rails_api_app`).

### Findings & Fixes
1.  **Rails API Compatibility**:
    -   `ActionController::API` does not include helpers by default.
    -   **Fix**: Explicitly included `Salvia::Helpers` in `ApplicationController` (or ensure Railtie handles it correctly for API mode).
    -   `render html:` in API mode works but requires `html_safe` string to avoid escaping.
    -   **Fix**: Updated `ssr` helper to return `html_safe` string.

2.  **SSR & DOM Mocks**:
    -   Libraries like `@hotwired/turbo` (imported in `vendor_setup.ts`) access DOM globals (`window`, `document`, `HTMLFormElement`, `Event`, `CustomEvent`, `URL`, `requestAnimationFrame`) immediately upon loading.
    -   QuickJS environment is minimal and lacks these globals, causing SSR to crash with `ReferenceError`.
    -   **Fix**: Added extensive DOM mocks in `Salvia::SSR::QuickJS#generate_console_shim`.

3.  **Configuration**:
    -   `deno.json` path resolution was incorrect when running from Rails root (it expected it in root, but `salvia install` puts it in `salvia/`).
    -   **Fix**: Added `deno_config_path` to `Salvia::Configuration` and updated `Salvia::Sidecar` to resolve it to an absolute path.

4.  **Debugging**:
    -   Logs from QuickJS were not flushed if an exception occurred during execution.
    -   **Fix**: Updated `eval_js` to flush logs in `rescue` block.

### Status
-   ✅ Rails API app renders SSR HTML correctly.
-   ✅ JIT compilation works via Deno Sidecar.
-   ✅ Import Maps are injected correctly.
