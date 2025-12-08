require_relative "config/environment"

use Rack::Static,
  urls: ["/assets"],
  root: "public",
  header_rules: [
    [:all, { "cache-control" => "public, max-age=31536000" }]
  ]

# Islands 用 (app/islands を /islands として公開)
use Rack::Static,
  urls: ["/islands"],
  root: "app"

use Rack::Session::Cookie,
  key: "_demo_app_session",
  secret: ENV.fetch("SESSION_SECRET") { SecureRandom.hex(64) }

use Rack::Protection, use: [:authenticity_token, :cookie_tossing, :form_token, :remote_referrer, :session_hijacking]

# ロギング
use Rack::CommonLogger, Salvia.logger

run Salvia::Application.new
