require_relative 'test_helper'

class HarnessTest < BlogTest
  def test_harness_exposes_the_sinatra_app
    assert_equal Sinatra::Application, app
  end
end
