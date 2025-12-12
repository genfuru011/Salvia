require "test_helper"

class GeneratorTest < Minitest::Test
  class PostsResource < Sage::Resource
    rpc :like, params: { id: Integer } do |ctx, id|
      { liked: true }
    end

    rpc :create, params: { title: String, draft: ::TrueClass } do |ctx, title, draft|
      { id: 1 }
    end
  end

  class TestApp < Sage::Base
    mount "/posts", PostsResource
  end

  def test_generate_dts
    generator = Sage::Generator.new(TestApp)
    dts = generator.generate_dts

    assert_includes dts, "export interface RpcClient {"
    assert_includes dts, "posts: {"
    assert_includes dts, "like(params: { id: number }): Promise<any>;"
    assert_includes dts, "create(params: { title: string, draft: boolean }): Promise<any>;"
  end

  def test_generate_client
    generator = Sage::Generator.new(TestApp)
    client = generator.generate_client

    assert_includes client, "const createProxy"
    assert_includes client, "export const rpc = createProxy() as RpcClient;"
    assert_includes client, "fetch(\"/\" + path"
  end
end
