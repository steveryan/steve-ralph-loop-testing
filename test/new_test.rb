require_relative 'test_helper'

class NewTest < BlogTest
  def test_get_new_renders_the_form
    get '/new'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'name="title"'
    assert_includes last_response.body, '<textarea name="body"'
    assert_includes last_response.body, 'type="submit"'
  end

  def test_post_creates_a_post_and_is_findable
    before = Post.all.size

    post '/', title: 'new flow title', body: 'new flow body'

    assert_equal before + 1, Post.all.size

    found = Post.find_by_title('new flow title')
    refute_nil found
    assert_equal 'new flow title', found['title']
    assert_equal 'new flow body', found['body']
  end
end
