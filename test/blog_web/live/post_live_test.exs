defmodule BlogWeb.PostLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Blog.Content

  describe "Index" do
    test "lists existing posts with links to their slug pages", %{conn: conn} do
      {:ok, first} = Content.create_post(%{title: "Hello World", body: "first body"})
      {:ok, second} = Content.create_post(%{title: "Second Post", body: "second body"})

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, ~s|a[href="/posts/#{first.slug}"]|, "Hello World")
      assert has_element?(view, ~s|a[href="/posts/#{second.slug}"]|, "Second Post")
    end

    test "renders the posts list container with an empty state when there are no posts",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "ul#posts")
      refute has_element?(view, "ul#posts a")
    end

    test "shows a link to create a new post", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, ~s|a[href="/posts/new"]|, "New Post")
    end
  end

  describe "New" do
    test "creates a post and redirects to its slug page on valid submit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/new")

      view
      |> form("#post-form", post: %{title: "My New Post", body: "Hello **world**"})
      |> render_submit()

      assert_redirect(view, "/posts/my-new-post")

      post = Content.get_post_by_slug!("my-new-post")
      assert post.title == "My New Post"
      assert post.body == "Hello **world**"
    end

    test "shows validation errors and creates nothing on blank submit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/posts/new")

      html =
        view
        |> form("#post-form", post: %{title: "", body: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
      assert Content.list_posts() == []
    end
  end

  describe "Show" do
    test "renders the post title and its Markdown body as HTML", %{conn: conn} do
      {:ok, post} =
        Content.create_post(%{title: "Rendered Post", body: "Hello **world**"})

      {:ok, view, html} = live(conn, ~p"/posts/#{post.slug}")

      assert has_element?(view, "h1", "Rendered Post")
      assert html =~ "<strong>world</strong>"
    end

    test "raises a 404 for an unknown slug", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/posts/does-not-exist")
      end
    end

    test "supports the create then view flow end-to-end", %{conn: conn} do
      {:ok, new_view, _html} = live(conn, ~p"/posts/new")

      new_view
      |> form("#post-form", post: %{title: "End To End", body: "This is **bold** text"})
      |> render_submit()

      assert_redirect(new_view, "/posts/end-to-end")

      {:ok, show_view, html} = live(conn, ~p"/posts/end-to-end")

      assert has_element?(show_view, "h1", "End To End")
      assert html =~ "<strong>bold</strong>"
    end
  end
end
