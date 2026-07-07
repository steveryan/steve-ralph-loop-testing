defmodule Blog.ContentTest do
  use Blog.DataCase

  alias Blog.Content

  describe "posts" do
    alias Blog.Content.Post

    import Blog.ContentFixtures

    @invalid_attrs %{title: nil, body: nil}

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Content.list_posts() == [post]
    end

    test "list_posts/0 returns posts newest-first" do
      oldest = post_fixture(title: "oldest")
      middle = post_fixture(title: "middle")
      newest = post_fixture(title: "newest")

      assert Content.list_posts() == [newest, middle, oldest]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Content.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      valid_attrs = %{title: "some title", body: "some body content"}

      assert {:ok, %Post{} = post} = Content.create_post(valid_attrs)
      assert post.title == "some title"
      assert post.body == "some body content"
    end

    test "create_post/1 with a body shorter than 10 characters returns error changeset" do
      short_attrs = %{title: "some title", body: "too short"}

      assert {:error, %Ecto.Changeset{} = changeset} = Content.create_post(short_attrs)
      assert "should be at least 10 character(s)" in errors_on(changeset).body
    end

    test "create_post/1 succeeds when body is at least 10 characters" do
      long_attrs = %{title: "some title", body: "long enough"}

      assert {:ok, %Post{} = post} = Content.create_post(long_attrs)
      assert post.body == "long enough"
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()
      update_attrs = %{title: "some updated title", body: "some updated body"}

      assert {:ok, %Post{} = post} = Content.update_post(post, update_attrs)
      assert post.title == "some updated title"
      assert post.body == "some updated body"
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_post(post, @invalid_attrs)
      assert post == Content.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Content.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Content.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Content.change_post(post)
    end
  end
end
