class HomeResource < Sage::Resource
  rpc :hello, params: { name: String } do |ctx, name|
    { message: "Hello, #{name}!" }
  end

  def index
    ctx.render "Home", title: "Welcome to Sage"
  end
end
