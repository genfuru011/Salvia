# Salvia.rb Context for AI Agents

> このファイルは、AI エージェントがプロジェクトのコンテキストを素早く理解するためのメタドキュメントです。

---

## 🌿 Project Overview

**Salvia.rb** は、"Wisdom for Rubyists" を掲げる軽量 Ruby MVC フレームワークです。
Rails ほど重厚ではなく、Sinatra ほどミニマルではない、"Just Right" な立ち位置を目指しています。

- **HTML First**: JSON API ではなく HTML を返すことを主眼に置く
- **HTMX Native**: HTMX を前提とした Smart Rendering を搭載
- **No Node.js**: `tailwindcss-ruby` や Import Maps を活用し、Node.js への依存を排除
- **ActiveRecord**: ORM には標準的な ActiveRecord を採用

## 📍 Current Status

- **Current Version**: v0.4.0 (Production Ready)
- **Next Milestone**: v0.5.0 (Rich UI & Advanced Features)
- **Ultimate Goal**: v1.0.0 (Stable Release)

## 📂 Directory Structure

```
Salvia/
├── salvia_rb/          # Gem Source Code
│   ├── lib/salvia_rb/  # Core Logic (Router, Controller, etc.)
│   └── exe/            # CLI Entry Point
├── docs/               # Documentation
│   ├── design/         # Architecture & Strategy
│   ├── development/    # Roadmap & Implementation Notes
│   ├── security/       # Security Assessment & Guides
│   └── meta/           # Meta docs (this file)
└── ...
```

## 📚 Key Documents

1. **[docs/design/ARCHITECTURE.md](../design/ARCHITECTURE.md)**
   - フレームワークの内部構造、リクエスト処理フロー、主要コンポーネントの解説。
   - 実装に着手する前に必ず確認すること。

2. **[docs/development/ROADMAP.md](../development/ROADMAP.md)**
   - 開発の進行状況と将来の計画。
   - 次のタスクを確認するために使用する。

3. **[docs/design/Strategy.md](../design/Strategy.md)**
   - コミットメッセージの規約、ブランチ戦略、リリースの手順。

4. **[docs/security/SECURITY_GUIDE.md](../security/SECURITY_GUIDE.md)**
   - セキュリティ実装のベストプラクティス。

## 🛠️ Development Rules

- **Keep it Simple**: 複雑なメタプログラミングより、明示的で読みやすいコードを優先する。
- **Minimal Changes**: 既存のコードを壊さないよう、変更は最小限に留める。
- **Documentation**: 機能追加時は必ずドキュメント（README, CHANGELOG, IMPLEMENTATION）を更新する。
- **Testing**: 新機能には必ずテストを追加する (`test_app` を生成して検証)。

## 🚀 Next Tasks (Phase 4)

1. **HTMX Helpers**: `htmx_link_to`, `htmx_form_for` などのヘルパー実装
2. **View Components**: 再利用可能な UI コンポーネントの仕組み
3. **Advanced Features**: WebSocket, Background Jobs などの調査・設計

---
*Last Updated: 2025-12-08*
