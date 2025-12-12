# Sage Middleware Guide

Sage uses standard **Rack Middleware**. If you have written middleware for Rack, Sinatra, or Rails, you already know how to write middleware for Sage.

## 1. Anatomy of a Middleware

A middleware is a Ruby class that follows this pattern:

```ruby
class MyMiddleware
  # 1. Initialize is called once when the app starts.
  # @param app [Proc] The next application/middleware in the stack.
  # @param args [Any] Arguments passed to `use`.
  def initialize(app, *args)
    @app = app
    @options = args.first || {}
  end

  # 2. Call is called for every request.
  # @param env [Hash] The Rack environment.
  # @return [Array] Standard Rack response [status, headers, body].
  def call(env)
    # --- Before Request ---
    puts "Received request: #{env['PATH_INFO']}"

    # Call the next middleware/app
    status, headers, body = @app.call(env)

    # --- After Request ---
    headers["X-Custom-Header"] = "Sage"

    # Return the response
    [status, headers, body]
  end
end
```

## 2. Using Middleware

Register middleware in your `App` class using the `use` keyword.

```ruby
class App < Sage::Base
  # Pass arguments to initialize
  use MyMiddleware, option: "value"
  
  # You can also use existing Rack gems
  use Rack::Session::Cookie, secret: "secret"
  
  get "/" do |ctx|
    ctx.text "Hello"
  end
end
```

## 3. Example: Authentication Middleware

```ruby
class AuthMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    
    # Check for token
    unless req.params["token"] == "secret"
      return [401, { "Content-Type" => "text/plain" }, ["Unauthorized"]]
    end

    # Continue if valid
    @app.call(env)
  end
end
```
