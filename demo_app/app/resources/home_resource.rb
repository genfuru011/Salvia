class HomeResource < Sage::Resource
  get "/" do |ctx|
    ctx.redirect "/todos"
  end
end
