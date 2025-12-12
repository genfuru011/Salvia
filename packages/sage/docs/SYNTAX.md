# Sage Syntax Design (Final)

## 1. The App (Entry Point)
Simple, flat, and intuitive.

```ruby
# app.rb
require "sage"

class App < Sage::Base
  # Standard Route (SSR)
  get "/" do |ctx|
    ctx.render "Home", title: "Welcome to Sage"
  end

  # Grouping
  group "/users" do
    get "/" do |ctx|
      # ...
    end
  end

  # Mounting Resources
  mount "/posts", PostsResource
end
```

## 2. The Resource (Hybrid Controller)
Combines Standard Routing and RPC in one class.

```ruby
# app/resources/posts_resource.rb
class PostsResource < Sage::Resource
  # --- Standard Routing (HTML/SSR) ---
  
  # Method-based (Rails-like)
  def index
    @posts = Post.all
    render "Posts/Index", posts: @posts
  end

  def show(id)
    @post = Post.find(id)
    render "Posts/Show", post: @post
  end

  # Block-based (Sinatra-like) is also allowed
  get "/archive" do |ctx|
    ctx.render "Posts/Archive"
  end

  # --- RPC (Server Actions) ---
  
  # Define RPC with 'rpc' keyword
  # Generates: POST /posts/like
  # TS Client: rpc.posts.like({ id: 1 })
  rpc :like do |id: Integer|
    post = Post.find(id)
    post.increment!(:likes)
    { likes: post.likes } # Returns JSON
  end

  # RPC with complex params
  rpc :create_comment do |post_id: Integer, content: String|
    Comment.create!(post_id: post_id, content: content)
    { success: true }
  end
end
```

## 3. The Client (TSX)
Import `rpc` from virtual module.

```tsx
import { rpc } from "sage/client";

// ...
await rpc.posts.like({ id: 1 });
```
