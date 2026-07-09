require_relative 'test_helper'

class RecentPostsTest < BlogTest
  def test_home_lists_only_the_10_newest_posts_newest_first_with_underscore_urls
    # Create 11 posts oldest-first; titles contain spaces to exercise slug conversion.
    (1..11).each do |n|
      Post.create(title: "post #{n}", body: "body #{n}")
    end

    get '/'

    assert_equal 200, last_response.status
    body = last_response.body

    assert_includes body, 'Recent Posts'

    # Post links in document order.
    slugs = body.scan(%r{href="/([^"]+)"}).flatten

    # Newest-first: post 11 .. post 2 (post 1 is the 11th-newest and excluded).
    expected = 11.downto(2).map { |n| "post_#{n}" }

    assert_equal expected, slugs
    assert_equal 10, slugs.size

    # Link text is the human title and href uses underscores.
    assert_includes body, '<a href="/post_11">post 11</a>'

    # The 11th-newest post must not appear in the list.
    refute_includes slugs, 'post_1'
  end
end
