# セキュリティガイド

Salvia.rb アプリケーションを安全に開発・運用するためのガイドです。

---

## 目次

1. [CSRF (クロスサイトリクエストフォージェリ) 対策](#csrf-対策)
2. [XSS (クロスサイトスクリプティング) 対策](#xss-対策)
3. [SQL インジェクション対策](#sql-インジェクション対策)
4. [認証と認可](#認証と認可)
5. [セッション管理](#セッション管理)
6. [ファイルアップロード](#ファイルアップロード)
7. [機密情報の管理](#機密情報の管理)
8. [セキュリティヘッダー](#セキュリティヘッダー)
9. [Rate Limiting](#rate-limiting)
10. [依存関係の管理](#依存関係の管理)

---

## CSRF 対策

CSRF (Cross-Site Request Forgery) は、正規ユーザーのセッションを悪用して不正なリクエストを送信する攻撃です。

### 基本的な実装

```ruby
# config.ru
use Rack::Protection, use: [:authenticity_token, :form_token]
```

### コントローラーでの使用

```ruby
class ApplicationController < Salvia::Controller
  # CSRF トークンを生成
  def csrf_token
    session[:csrf] ||= SecureRandom.base64(32)
  end

  # CSRF トークンを検証
  def verify_csrf_token!
    return if request.get? || request.head?
    
    token = request.env['HTTP_X_CSRF_TOKEN'] || 
            params['authenticity_token']
    
    unless valid_csrf_token?(token)
      response.status = 403
      render 'errors/forbidden', layout: false
      raise "Invalid CSRF token"
    end
  end

  private

  def valid_csrf_token?(token)
    return false if token.nil? || session[:csrf].nil?
    Rack::Utils.secure_compare(token, session[:csrf])
  end
end
```

### ビューでの使用

```erb
<!-- レイアウトファイルで CSRF トークンを設定 -->
<head>
  <%= csrf_meta_tags %>
</head>

<!-- フォームでは自動的に含まれる (Rack::Protection が処理) -->
<form method="POST" action="/users">
  <!-- フォームフィールド -->
</form>
```

### HTMX との連携

```javascript
// app.js
document.addEventListener('htmx:configRequest', (event) => {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (csrfToken) {
    event.detail.headers['X-CSRF-Token'] = csrfToken;
  }
});
```

---

## XSS 対策

XSS (Cross-Site Scripting) は、悪意のあるスクリプトを Web ページに挿入する攻撃です。

### ERB テンプレートでの自動エスケープ

```ruby
# controller.rb で Erubi のエスケープモードを有効化
def render_template(template_path, locals = {}, &block)
  full_path = resolve_template_path(template_path)
  
  # escape: true でエスケープを有効化
  template = Tilt::ErubiTemplate.new(full_path, escape: true)
  template.render(self, locals, &block)
end
```

### ビューでの使用

```erb
<!-- ✅ 安全: 自動的にエスケープされる -->
<p><%= @user.name %></p>
<p><%= @post.content %></p>

<!-- ❌ 危険: エスケープされない -->
<p><%== @user.bio %></p>
<p><%= raw @user.description %></p>

<!-- ✅ 信頼できる HTML のみ raw を使用 -->
<div class="content">
  <%= raw sanitize_html(@post.body) %>
</div>
```

### HTML サニタイゼーション

信頼できない HTML を表示する必要がある場合:

```ruby
# Gemfile
gem 'sanitize'

# ヘルパーメソッド
def sanitize_html(html)
  Sanitize.fragment(html, Sanitize::Config::RELAXED)
end
```

### JavaScript での使用

```erb
<!-- ❌ 危険: JavaScript に直接埋め込み -->
<script>
  const userName = "<%= @user.name %>";
</script>

<!-- ✅ 安全: JSON エンコード -->
<script>
  const userName = <%= @user.name.to_json %>;
</script>

<!-- ✅ より安全: data 属性を使用 -->
<div id="user-info" data-name="<%= @user.name %>"></div>
<script>
  const userName = document.getElementById('user-info').dataset.name;
</script>
```

---

## SQL インジェクション対策

SQL インジェクションは、SQL クエリに悪意のあるコードを挿入する攻撃です。

### 安全な ActiveRecord の使用

```ruby
# ✅ 安全: パラメータ化されたクエリ
User.where("name = ?", params[:name])
User.where(name: params[:name])
User.where("age > ? AND city = ?", params[:age], params[:city])

# ✅ 安全: ハッシュ形式
User.where(email: params[:email], active: true)

# ❌ 危険: 文字列補間
User.where("name = '#{params[:name]}'")  # SQL injection vulnerable!

# ❌ 危険: 生の SQL
User.find_by_sql("SELECT * FROM users WHERE id = #{params[:id]}")

# ✅ 安全: プレースホルダーを使用
User.find_by_sql(["SELECT * FROM users WHERE id = ?", params[:id]])
```

### LIKE クエリの安全な使用

```ruby
# サニタイゼーションヘルパー
def sanitize_sql_like(string)
  string.to_s.gsub(/[%_\\]/) { |x| "\\#{x}" }
end

# 使用例
search_term = sanitize_sql_like(params[:query])
User.where("name LIKE ?", "%#{search_term}%")
```

### 動的な ORDER BY の安全な実装

```ruby
# ❌ 危険: ユーザー入力を直接使用
User.order(params[:sort])

# ✅ 安全: ホワイトリスト方式
ALLOWED_SORT_COLUMNS = ['name', 'email', 'created_at']

def safe_order_column(column)
  ALLOWED_SORT_COLUMNS.include?(column) ? column : 'created_at'
end

User.order(safe_order_column(params[:sort]))
```

---

## 認証と認可

### パスワード認証の実装

```ruby
# Gemfile
gem 'bcrypt'

# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: :password_digest_changed?
  validates :password, format: { 
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, 
    message: "must include at least one lowercase letter, one uppercase letter, and one digit" 
  }, if: :password_digest_changed?
end

# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      reset_session  # セッション固定攻撃対策
      session[:user_id] = user.id
      session[:csrf] = SecureRandom.base64(32)
      
      redirect_to root_path
    else
      flash.now[:alert] = "Invalid email or password"
      render 'new'
    end
  end

  def destroy
    reset_session
    redirect_to root_path
  end
end
```

### 認可の実装

```ruby
# app/models/user.rb
class User < ApplicationRecord
  enum role: { user: 0, moderator: 1, admin: 2 }
  
  def can_edit?(resource)
    admin? || resource.user_id == id
  end
  
  def can_delete?(resource)
    admin?
  end
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_edit!, only: [:edit, :update]
  before_action :authorize_delete!, only: [:destroy]

  private

  def authenticate_user!
    unless current_user
      flash[:alert] = "Please sign in to continue"
      redirect_to login_path
    end
  end

  def authorize_edit!
    @post = Post.find(params[:id])
    unless current_user.can_edit?(@post)
      response.status = 403
      render 'errors/forbidden'
    end
  end

  def authorize_delete!
    @post = Post.find(params[:id])
    unless current_user.can_delete?(@post)
      response.status = 403
      render 'errors/forbidden'
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
end
```

---

## セッション管理

### 安全なセッション設定

```ruby
# config.ru
use Rack::Session::Cookie,
  key: "_myapp_session",
  secret: ENV.fetch("SESSION_SECRET") {
    raise "SESSION_SECRET must be set!" if ENV['RACK_ENV'] == 'production'
    SecureRandom.hex(64)
  },
  same_site: :lax,           # CSRF 対策
  httponly: true,            # JavaScript からのアクセスを防ぐ
  secure: ENV['RACK_ENV'] == 'production',  # HTTPS のみ
  expire_after: 24 * 3600    # 24時間
```

### セッション固定攻撃の防止

```ruby
# ログイン後にセッションを再生成
def create
  user = User.find_by(email: params[:email])
  
  if user&.authenticate(params[:password])
    # 古いセッション ID を破棄して新しいものを発行
    reset_session
    session[:user_id] = user.id
    session[:csrf] = SecureRandom.base64(32)
    
    redirect_to root_path
  end
end
```

### セッションタイムアウト

```ruby
# app/controllers/application_controller.rb
class ApplicationController < Salvia::Controller
  before_action :check_session_timeout

  private

  def check_session_timeout
    if session[:last_activity_at]
      timeout = 30 * 60  # 30分
      if Time.now - Time.parse(session[:last_activity_at]) > timeout
        reset_session
        flash[:alert] = "Your session has expired. Please sign in again."
        redirect_to login_path
      end
    end
    
    session[:last_activity_at] = Time.now.to_s
  end
end
```

---

## ファイルアップロード

### 安全なファイルアップロードの実装

```ruby
# app/controllers/uploads_controller.rb
class UploadsController < ApplicationController
  ALLOWED_TYPES = {
    'image/jpeg' => '.jpg',
    'image/png' => '.png',
    'application/pdf' => '.pdf'
  }
  MAX_SIZE = 10 * 1024 * 1024  # 10MB

  def create
    file = params[:file]
    
    validate_file!(file)
    
    # ファイル名をサニタイズ
    safe_filename = sanitize_filename(file[:filename])
    unique_filename = "#{SecureRandom.uuid}#{File.extname(safe_filename)}"
    
    # Web ルート外に保存
    upload_dir = File.join(Salvia.root, 'storage', 'uploads', current_user.id.to_s)
    FileUtils.mkdir_p(upload_dir)
    
    destination = File.join(upload_dir, unique_filename)
    
    File.open(destination, 'wb') do |f|
      f.write(file[:tempfile].read)
    end
    
    # ファイル権限を制限
    File.chmod(0644, destination)
    
    redirect_to uploads_path, notice: "File uploaded successfully"
  end

  private

  def validate_file!(file)
    raise "File is required" if file.nil? || file[:tempfile].nil?
    
    # サイズチェック
    size = file[:tempfile].size
    raise "File too large (max #{MAX_SIZE / 1024 / 1024}MB)" if size > MAX_SIZE
    
    # MIME タイプチェック
    mime_type = file[:type]
    raise "Invalid file type" unless ALLOWED_TYPES.key?(mime_type)
    
    # 拡張子チェック
    ext = File.extname(file[:filename]).downcase
    raise "Invalid file extension" unless ALLOWED_TYPES[mime_type] == ext
  end

  def sanitize_filename(filename)
    # パストラバーサル攻撃を防ぐ
    filename = File.basename(filename)
    # 危険な文字を除去
    filename.gsub(/[^a-zA-Z0-9._-]/, '_')
  end
end
```

### ファイル配信

```ruby
# app/controllers/downloads_controller.rb
class DownloadsController < ApplicationController
  def show
    # パストラバーサル攻撃を防ぐ
    filename = File.basename(params[:filename])
    file_path = File.join(Salvia.root, 'storage', 'uploads', current_user.id.to_s, filename)
    
    # ファイルの存在確認
    unless File.exist?(file_path)
      response.status = 404
      return render 'errors/not_found'
    end
    
    # 所有者チェック
    unless authorized_to_download?(file_path)
      response.status = 403
      return render 'errors/forbidden'
    end
    
    # 安全に配信
    send_file(file_path)
  end

  private

  def send_file(path)
    response.status = 200
    response['Content-Type'] = 'application/octet-stream'
    response['Content-Disposition'] = "attachment; filename=\"#{File.basename(path)}\""
    response.write(File.read(path))
  end

  def authorized_to_download?(path)
    # ユーザーのディレクトリ内のファイルのみ許可
    user_dir = File.join(Salvia.root, 'storage', 'uploads', current_user.id.to_s)
    File.expand_path(path).start_with?(File.expand_path(user_dir))
  end
end
```

---

## 機密情報の管理

### 環境変数の使用

```ruby
# .env (Git には含めない)
SESSION_SECRET=your-secret-key-here
DATABASE_URL=postgresql://user:password@localhost/myapp
API_KEY=your-api-key

# .env.example (Git に含める)
SESSION_SECRET=
DATABASE_URL=
API_KEY=

# Gemfile
gem 'dotenv', groups: [:development, :test]

# config/environment.rb
require 'dotenv/load' if Salvia.development? || Salvia.test?
```

### ログからの機密情報除外

```ruby
# lib/salvia_rb/parameter_filter.rb
module Salvia
  class ParameterFilter
    FILTERED_PARAMS = %w[
      password
      password_confirmation
      token
      secret
      api_key
      access_token
      refresh_token
      credit_card
      ssn
    ]
    
    def self.filter(params)
      params.transform_keys(&:to_s).each_with_object({}) do |(key, value), result|
        result[key] = if FILTERED_PARAMS.any? { |filtered| key.to_s.include?(filtered) }
          '[FILTERED]'
        elsif value.is_a?(Hash)
          filter(value)
        else
          value
        end
      end
    end
  end
end

# 使用例
logger.info "Request params: #{ParameterFilter.filter(params).inspect}"
```

---

## セキュリティヘッダー

### 推奨ヘッダーの設定

```ruby
# lib/security_headers.rb
class SecurityHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    
    # XSS 対策
    headers['X-Content-Type-Options'] = 'nosniff'
    headers['X-XSS-Protection'] = '1; mode=block'
    
    # クリックジャッキング対策
    headers['X-Frame-Options'] = 'DENY'
    
    # リファラーポリシー
    headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    
    # 権限ポリシー
    headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
    
    # HTTPS 強制 (本番環境のみ)
    if env['RACK_ENV'] == 'production'
      headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'
    end
    
    # Content Security Policy
    headers['Content-Security-Policy'] = content_security_policy
    
    [status, headers, response]
  end

  private

  def content_security_policy
    [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' https://unpkg.com",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "font-src 'self'",
      "connect-src 'self'",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'"
    ].join('; ')
  end
end

# config.ru
use SecurityHeaders
```

---

## Rate Limiting

### Rack::Attack の設定

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
require 'rack/attack'

class Rack::Attack
  # IP アドレスごとのレート制限
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # ログインエンドポイントの保護
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.ip
    end
  end

  # API エンドポイントの保護
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    if req.path.start_with?('/api/')
      req.ip
    end
  end

  # ブロック時のレスポンス
  self.blocklisted_responder = lambda do |env|
    [429, 
     {'Content-Type' => 'text/html'}, 
     ['<h1>Too Many Requests</h1><p>Please try again later.</p>']
    ]
  end

  # ホワイトリスト (信頼できる IP)
  safelist('allow from localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end
end

# config.ru
use Rack::Attack
```

---

## 依存関係の管理

### Bundler Audit の使用

```bash
# インストール
gem install bundler-audit

# データベースの更新
bundle-audit update

# 脆弱性チェック
bundle-audit check
```

### CI/CD での自動チェック

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
      
      - name: Update vulnerability database
        run: bundle-audit update
      
      - name: Check for vulnerabilities
        run: bundle-audit check
```

---

## まとめ

セキュリティは継続的なプロセスです。以下のポイントを常に意識してください:

1. **ユーザー入力を信頼しない** - すべての入力を検証・サニタイズ
2. **最小権限の原則** - 必要最小限の権限のみ付与
3. **深層防御** - 複数のセキュリティ層で保護
4. **定期的な更新** - 依存関係とセキュリティパッチの適用
5. **セキュアデフォルト** - デフォルトで安全な設定を使用

---

**参考資料**:
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Ruby on Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)

**最終更新**: 2025-12-08
