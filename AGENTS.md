# Salvia.rb 開発戦略

> 個人開発プロジェクトのためのシンプルな開発フロー

---

## 📝 コミット戦略

### 形式

```
<種別>: <日本語での説明>

例:
feat: ルーターの基本実装
fix: パーシャルレンダリングのバグ修正
docs: READMEにクイックスタート追加
refactor: コントローラーのリファクタリング
```

### 種別（Prefix）

| Prefix | 用途 |
|--------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `docs` | ドキュメント |
| `refactor` | リファクタリング（機能変更なし） |
| `test` | テスト追加・修正 |
| `chore` | ビルド、依存関係、設定変更 |

### コミット粒度

個人開発なので、**細かすぎない粒度**でOK：

```
✅ 良い例:
feat: Phase 0 の基本実装（Router, Controller, CLI）
docs: ドキュメント整備（README, ARCHITECTURE, Strategy）

❌ 細かすぎる例:
feat: Router クラスを追加
feat: Router に root メソッドを追加
feat: Router に get メソッドを追加
```

---

## 🔀 ブランチ戦略

### シンプル版（推奨）

個人開発では **main ブランチのみ** でシンプルに運用：

```
main ─────●─────●─────●─────●─────●
          │     │     │     │     │
        v0.1.0  │   v0.2.0  │   v0.3.0
                │           │
            日々の開発   日々の開発
```

**ルール:**
- `main` に直接コミット
- リリース時にタグを打つ（`v0.1.0`, `v0.2.0`...）
- 大きな実験は一時的にブランチを切ってもOK

### 拡張版（将来必要になったら）

コントリビューターが増えたら：

```
main (安定版)
  └── develop (開発統合)
        ├── feature/phase-1-zeitwerk
        └── feature/phase-2-csrf
```

---

## 🏷️ バージョニング

[Semantic Versioning](https://semver.org/) に従う：

```
v0.1.0  - 最初のリリース（実験的）
v0.2.0  - Developer Experience
v0.3.0  - Security
v0.4.0  - Production Ready
v1.0.0  - 安定版（破壊的変更なし）
```

### タグの打ち方

```bash
git tag -a v0.1.0 -m "Phase 0: Foundation"
git push origin v0.1.0
```

---

## 📋 リリースチェックリスト

### リリース前

- [ ] すべてのテストが通る
- [ ] CHANGELOG.md を更新
- [ ] version.rb のバージョンを更新
- [ ] README に破壊的変更を記載（あれば）

### リリース手順

```bash
# 1. バージョン更新
# lib/salvia_rb/version.rb を編集

# 2. コミット
git add -A
git commit -m "chore: v0.x.0 リリース準備"

# 3. タグ
git tag -a v0.x.0 -m "Phase X: タイトル"

# 4. プッシュ
git push origin main
git push origin v0.x.0

# 5. Gem 公開（準備ができたら）
gem build salvia_rb.gemspec
gem push salvia_rb-0.x.0.gem
```

---

## 📁 今回の初回コミット

```bash
git add -A
git commit -m "feat: Salvia.rb v0.1.0 初期実装

- Core: Router, Controller, Application, Database
- CLI: new, server, console, db:*, css:*, routes
- Smart Rendering: HTMX リクエスト自動検出
- ドキュメント: README, ARCHITECTURE, ROADMAP, CHANGELOG"

git tag -a v0.1.0 -m "Phase 0: Foundation"
```

---

## 🤔 迷ったときは

> **シンプルに保つ**

- ブランチが必要か迷ったら → main で直接作業
- コミットを分けるか迷ったら → まとめてOK
- 完璧を目指さない → 動くものを優先

個人開発の強みは **スピード** と **柔軟性**。
プロセスに縛られすぎないことが大事。
ドキュメントの更新を忘れずに

---

*最終更新: 2025-01*

