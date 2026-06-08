require_relative 'test_helper'

class PostTest < BlogTest
  def test_create_then_all_includes_the_post
    created = Post.create(title: 'x', body: 'y')

    refute_nil created
    assert_equal 'x', created['title']
    assert_equal 'y', created['body']

    assert_includes Post.all, created
    assert_includes Post.all.map { |p| p['title'] }, 'x'
  end

  def test_find_by_title_returns_the_created_post
    Post.create(title: 'x', body: 'y')

    found = Post.find_by_title('x')

    refute_nil found
    assert_equal 'x', found['title']
    assert_equal 'y', found['body']
  end

  def test_all_is_newest_first_across_multiple_inserts
    Post.create(title: 'first', body: 'a')
    Post.create(title: 'second', body: 'b')
    Post.create(title: 'third', body: 'c')

    titles = Post.all.map { |p| p['title'] }

    assert_equal %w[third second first], titles
  end
end
