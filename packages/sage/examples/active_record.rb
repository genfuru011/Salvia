require "bundler/setup"
require "sage"
require "active_record"
require "sqlite3"

# 1. Setup Database
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Create Schema
ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string :title
    t.text :body
    t.integer :likes, default: 0
  end
end

# 2. Define Model
class Post < ActiveRecord::Base
end

# 3. Define Resource
class PostsResource < Sage::Resource
  # Standard Route
  get "/" do |ctx|
    posts = Post.all
    ctx.json(posts.as_json)
  end

  # RPC
  rpc :create, params: { title: String, body: String } do |ctx, title, body|
    post = Post.create!(title: title, body: body)
    { id: post.id, title: post.title }
  end

  rpc :like, params: { id: Integer } do |ctx, id|
    post = Post.find(id)
    post.increment!(:likes)
    { likes: post.likes }
  end
end

# 4. Define App
class App < Sage::Base
  # Use Connection Management Middleware
  use Sage::Middleware::ConnectionManagement

  mount "/posts", PostsResource
end

# 5. Run Server
if __FILE__ == $0
  server = Sage::Server.new(App.new)
  server.start(port: 3001)
end
