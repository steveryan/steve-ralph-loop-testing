require_relative 'test_helper'

class ShowTest < BlogTest
  def test_get_post_by_pretty_url_renders_title_and_body
    Post.create(title: 'test post', body: 'this is the post body')

    get '/test_post'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'test post'
    assert_includes last_response.body, 'this is the post body'
  end

  def test_unknown_slug_returns_404
    get '/does_not_exist'

    assert_equal 404, last_response.status
  end
end
