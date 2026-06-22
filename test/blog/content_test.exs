defmodule Blog.ContentTest do
  use Blog.DataCase, async: true

  alias Blog.Content
  alias Blog.Content.Post

  describe "create_post/1" do
    test "persists a post and derives a slug from the title" do
      assert {:ok, %Post{} = post} =
               Content.create_post(%{title: "My First Post", body: "Hello world"})

      assert post.id
      assert post.title == "My First Post"
      assert post.body == "Hello world"
      assert post.slug == "my-first-post"
    end

    test "produces distinct slugs for duplicate titles" do
      assert {:ok, first} = Content.create_post(%{title: "Same Title", body: "one"})
      assert {:ok, second} = Content.create_post(%{title: "Same Title", body: "two"})

      assert first.slug == "same-title"
      assert second.slug != first.slug
      assert second.slug =~ ~r/^same-title-\d+$/
    end

    test "honors an explicitly provided slug" do
      assert {:ok, post} =
               Content.create_post(%{title: "Custom", body: "x", slug: "my-custom-slug"})

      assert post.slug == "my-custom-slug"
    end

    test "requires a title and body" do
      assert {:error, changeset} = Content.create_post(%{})

      assert %{title: ["can't be blank"], body: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "list_posts/0" do
    test "returns posts newest first" do
      {:ok, oldest} = Content.create_post(%{title: "Oldest", body: "a"})
      {:ok, middle} = Content.create_post(%{title: "Middle", body: "b"})
      {:ok, newest} = Content.create_post(%{title: "Newest", body: "c"})

      slugs = Enum.map(Content.list_posts(), & &1.slug)

      assert slugs == [newest.slug, middle.slug, oldest.slug]
    end

    test "returns an empty list when there are no posts" do
      assert Content.list_posts() == []
    end
  end

  describe "get_post_by_slug!/1" do
    test "fetches the post matching the slug" do
      {:ok, post} = Content.create_post(%{title: "Findable", body: "here"})

      assert Content.get_post_by_slug!(post.slug).id == post.id
    end

    test "raises when no post matches the slug" do
      assert_raise Ecto.NoResultsError, fn ->
        Content.get_post_by_slug!("does-not-exist")
      end
    end
  end

  describe "get_post!/1" do
    test "fetches the post matching the id" do
      {:ok, post} = Content.create_post(%{title: "By Id", body: "body"})

      assert Content.get_post!(post.id).slug == post.slug
    end
  end

  describe "change_post/2" do
    test "returns a changeset for the post" do
      assert %Ecto.Changeset{} = Content.change_post(%Post{})
    end
  end
end
