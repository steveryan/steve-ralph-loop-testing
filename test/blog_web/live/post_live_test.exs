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
  end
end
