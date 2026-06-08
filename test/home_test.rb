require_relative 'test_helper'

class HomeTest < BlogTest
  def test_get_root_responds_200_with_welcome_text
    get '/'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Welcome to the blog'
  end
end
