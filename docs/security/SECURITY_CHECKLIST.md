# セキュリティチェックリスト

このドキュメントは、Salvia.rb アプリケーション開発時のセキュリティチェックリストです。

---

## 🔐 開発時のチェックリスト

### 入力検証
- [ ] すべてのユーザー入力は検証されているか?
- [ ] ホワイトリスト方式で許可する値を制限しているか?
- [ ] 入力長の制限を設定しているか?
- [ ] 特殊文字のサニタイゼーションを実施しているか?

### SQL インジェクション対策
- [ ] ActiveRecord のパラメータ化されたクエリを使用しているか?
- [ ] 生の SQL (`find_by_sql`, `execute`) を避けているか?
- [ ] 文字列補間 (`#{}`) を SQL クエリで使用していないか?
```ruby
# ❌ 危険
User.where("name = '#{params[:name]}'")

# ✅ 安全
User.where("name = ?", params[:name])
User.where(name: params[:name])
```

### XSS (クロスサイトスクリプティング) 対策
- [ ] ERB テンプレートで自動エスケープが有効か?
- [ ] ユーザー入力をそのまま `raw` で出力していないか?
- [ ] JavaScript 内に動的データを埋め込む際にエスケープしているか?
```erb
<!-- ✅ 安全: 自動エスケープ -->
<p><%= @user.name %></p>

<!-- ❌ 危険: エスケープなし -->
<p><%== @user.name %></p>
<p><%= raw @user.name %></p>
```

### CSRF (クロスサイトリクエストフォージェリ) 対策
- [ ] すべてのフォームに CSRF トークンが含まれているか?
- [ ] POST/PUT/PATCH/DELETE リクエストで CSRF トークンを検証しているか?
- [ ] HTMX リクエストに CSRF トークンが送信されているか?
```erb
<!-- ✅ フォームに CSRF トークンを含める -->
<%= csrf_meta_tags %>

<form method="POST" action="/users">
  <!-- フォームフィールド -->
</form>
```

### 認証・認可
- [ ] 認証が必要なアクションに `authenticate_user!` を実装しているか?
- [ ] 認可チェック (ユーザーがリソースにアクセスできるか) を実装しているか?
- [ ] パスワードは bcrypt などで安全にハッシュ化されているか?
- [ ] パスワードの最小文字数は 8文字以上か?
```ruby
class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!, only: [:edit, :update, :destroy]

  def update
    @post = Post.find(params[:id])
    # ...
  end

  private

  def authorize_user!
    @post = Post.find(params[:id])
    redirect_to root_path unless @post.user == current_user
  end
end
```

### セッション管理
- [ ] セッションシークレットは環境変数から読み込んでいるか?
- [ ] `secure` フラグを本番環境で有効にしているか?
- [ ] `httponly` フラグを設定しているか?
- [ ] セッションの有効期限を設定しているか?
- [ ] ログイン後にセッション ID を再生成しているか?
```ruby
# config.ru
use Rack::Session::Cookie,
  secret: ENV.fetch("SESSION_SECRET"),
  secure: ENV['RACK_ENV'] == 'production',
  httponly: true,
  same_site: :lax,
  expire_after: 24 * 3600
```

### リダイレクト
- [ ] ユーザー入力から URL を受け取る際に検証しているか?
- [ ] 外部サイトへのリダイレクトを許可する場合、ホワイトリストで制限しているか?
```ruby
# ❌ 危険: 任意の URL にリダイレクト
redirect_to params[:return_to]

# ✅ 安全: 内部 URL のみ許可
redirect_to params[:return_to] if internal_url?(params[:return_to])
```

### ファイルアップロード
- [ ] ファイルタイプを検証しているか (MIME タイプと拡張子)?
- [ ] ファイルサイズを制限しているか?
- [ ] ファイル名をサニタイズしているか?
- [ ] アップロード先は Web ルートの外か?
- [ ] 実行権限を付与していないか?

### 機密情報の取り扱い
- [ ] パスワード、トークン、API キーをログに出力していないか?
- [ ] エラーメッセージに機密情報が含まれていないか?
- [ ] 環境変数で機密情報を管理しているか?
- [ ] `.env` ファイルは `.gitignore` に含まれているか?
```ruby
# ❌ 危険: パスワードがログに出力される
logger.info "User params: #{params.inspect}"

# ✅ 安全: パスワードをフィルタリング
filtered_params = params.except(:password, :password_confirmation)
logger.info "User params: #{filtered_params.inspect}"
```

### セキュリティヘッダー
- [ ] `X-Frame-Options` を設定しているか?
- [ ] `X-Content-Type-Options: nosniff` を設定しているか?
- [ ] `Strict-Transport-Security` (HSTS) を本番環境で設定しているか?
- [ ] `Content-Security-Policy` を設定しているか?

### 依存関係
- [ ] 定期的に `bundle audit` を実行しているか?
- [ ] 依存関係は最新バージョンに更新されているか?
- [ ] セキュリティアドバイザリを確認しているか?
```bash
# Bundler Audit のインストール
gem install bundler-audit

# 脆弱性チェック
bundle audit check --update
```

### エラーハンドリング
- [ ] 本番環境でスタックトレースを表示していないか?
- [ ] エラーメッセージは一般的な内容か (詳細な情報を含まない)?
- [ ] エラーログはファイルに保存されているか?

### API エンドポイント
- [ ] Rate Limiting を実装しているか?
- [ ] API キーやトークンで認証しているか?
- [ ] CORS 設定は適切か?

---

## 🚀 デプロイ前のチェックリスト

### 環境変数
- [ ] `SESSION_SECRET` は安全なランダム値か?
- [ ] `DATABASE_URL` は環境変数で管理されているか?
- [ ] API キーやシークレットはコードに含まれていないか?

### HTTPS
- [ ] HTTPS を有効にしているか?
- [ ] HTTP から HTTPS へのリダイレクトを設定しているか?
- [ ] `Strict-Transport-Security` ヘッダーを設定しているか?

### データベース
- [ ] データベースのアクセス制限を設定しているか?
- [ ] データベースユーザーは最小限の権限か?
- [ ] バックアップは定期的に取得されているか?

### ログ
- [ ] ログファイルは適切に管理されているか?
- [ ] ログに機密情報が含まれていないか?
- [ ] ログローテーションを設定しているか?

### 監視
- [ ] エラー監視ツールを導入しているか (Sentry, Rollbar など)?
- [ ] パフォーマンス監視を設定しているか?
- [ ] セキュリティイベントの監視を設定しているか?

---

## 🛠️ セキュリティツール

### 開発環境
- **Bundler Audit**: Gem の脆弱性チェック
- **Brakeman**: Ruby/Rails の静的解析
- **RuboCop**: コード品質チェック

### 本番環境
- **Rack::Attack**: Rate Limiting
- **Rack::Protection**: セキュリティミドルウェア
- **Sentry/Rollbar**: エラー監視

### CI/CD
```yaml
# .github/workflows/security.yml
name: Security Check
on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.1
          bundler-cache: true
      
      - name: Install Bundler Audit
        run: gem install bundler-audit
      
      - name: Check for vulnerabilities
        run: bundle audit check --update
```

---

## 📚 参考資料

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Ruby on Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)

---

## 🔄 定期的なセキュリティレビュー

- **毎週**: 依存関係の脆弱性チェック (`bundle audit`)
- **毎月**: コードレビューでセキュリティ観点の確認
- **四半期ごと**: 包括的なセキュリティ監査
- **リリース前**: このチェックリストの全項目を確認

---

**最終更新**: 2025-12-08
