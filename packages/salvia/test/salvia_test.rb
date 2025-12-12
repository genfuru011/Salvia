require "test_helper"

class SalviaTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Salvia::VERSION
  end

  def test_configuration
    assert_instance_of Salvia::Core::Configuration, Salvia.config
  end
  
  def test_ssr_configuration
    # Should raise error if engine is unknown
    assert_raises(Salvia::SSR::EngineNotFoundError) do
      Salvia::SSR.configure(engine: :unknown)
    end
    
    # Should configure quickjs by default
    Salvia::SSR.configure(engine: :quickjs)
    assert Salvia::SSR.configured?
  end
end
