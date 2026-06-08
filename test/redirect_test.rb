require_relative 'test_helper'
require 'uri'

class RedirectTest < BlogTest
  def test_post_redirects_to_the_new_post_and_renders_it
    post '/', title: 'test post', body: 'redirect body'

    assert_equal 302, last_response.status
    location = last_response.headers['Location']
    refute_nil location
    assert_equal '/test_post', URI.parse(location).path

    follow_redirect!

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'test post'
    assert_includes last_response.body, 'redirect body'
  end
end
