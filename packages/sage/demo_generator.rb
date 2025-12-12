require_relative "lib/sage"

class PostsResource < Sage::Resource
  rpc :like, params: { id: Integer } do |ctx, id|
    { liked: true }
  end

  rpc :create, params: { title: String, draft: ::TrueClass } do |ctx, title, draft|
    { id: 1 }
  end
end

class App < Sage::Base
  mount "/posts", PostsResource
end

generator = Sage::Generator.new(App)

puts "--- client.d.ts ---"
puts generator.generate_dts
puts "\n--- client.ts ---"
puts generator.generate_client
