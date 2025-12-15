class HomeResource < Sage::Resource
  def index
    ctx.render "Home", title: "Welcome to Sage"
  end
end
