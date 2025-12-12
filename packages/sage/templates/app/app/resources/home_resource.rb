class HomeResource < Sage::Resource
  get "/" do |ctx|
    ctx.text "Welcome to Sage!"
  end
end
