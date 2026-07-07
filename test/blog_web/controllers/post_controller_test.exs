defmodule BlogWeb.PostControllerTest do
  use BlogWeb.ConnCase

  import Blog.ContentFixtures

  @create_attrs %{title: "some title", body: "some body content"}
  @update_attrs %{title: "some updated title", body: "some updated body"}
  @invalid_attrs %{title: nil, body: nil}

  describe "home page" do
    test "GET / renders the posts list", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Listing Posts"
    end
  end

  describe "index" do
    test "lists all posts", %{conn: conn} do
      conn = get(conn, ~p"/posts")
      assert html_response(conn, 200) =~ "Listing Posts"
    end

    test "shows each post's publication date", %{conn: conn} do
      post = post_fixture()
      formatted_date = Calendar.strftime(post.inserted_at, "%B %-d, %Y")

      conn = get(conn, ~p"/posts")
      assert html_response(conn, 200) =~ formatted_date
    end

    test "shows a pluralized post count in the header", %{conn: conn} do
      for _ <- 1..3, do: post_fixture()

      conn = get(conn, ~p"/posts")
      assert html_response(conn, 200) =~ "3 posts"
    end

    test "shows a singular post count when there is exactly one post", %{conn: conn} do
      post_fixture()

      conn = get(conn, ~p"/posts")
      response = html_response(conn, 200)
      assert response =~ "1 post"
      refute response =~ "1 posts"
    end
  end

  describe "show post" do
    setup [:create_post]

    test "renders a single post when linked directly", %{conn: conn, post: post} do
      conn = get(conn, ~p"/posts/#{post}")
      response = html_response(conn, 200)
      assert response =~ "Post #{post.id}"
      assert response =~ post.title
      assert response =~ post.body
    end
  end

  describe "new post" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/posts/new")
      assert html_response(conn, 200) =~ "New Post"
    end
  end

  describe "create post" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/posts", post: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/posts/#{id}"

      conn = get(conn, ~p"/posts/#{id}")
      assert html_response(conn, 200) =~ "Post #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/posts", post: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Post"
    end
  end

  describe "edit post" do
    setup [:create_post]

    test "renders form for editing chosen post", %{conn: conn, post: post} do
      conn = get(conn, ~p"/posts/#{post}/edit")
      assert html_response(conn, 200) =~ "Edit Post"
    end
  end

  describe "update post" do
    setup [:create_post]

    test "redirects when data is valid", %{conn: conn, post: post} do
      conn = put(conn, ~p"/posts/#{post}", post: @update_attrs)
      assert redirected_to(conn) == ~p"/posts/#{post}"

      conn = get(conn, ~p"/posts/#{post}")
      assert html_response(conn, 200) =~ "some updated title"
    end

    test "renders errors when data is invalid", %{conn: conn, post: post} do
      conn = put(conn, ~p"/posts/#{post}", post: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Post"
    end
  end

  describe "delete post" do
    setup [:create_post]

    test "deletes chosen post", %{conn: conn, post: post} do
      conn = delete(conn, ~p"/posts/#{post}")
      assert redirected_to(conn) == ~p"/posts"

      assert_error_sent 404, fn ->
        get(conn, ~p"/posts/#{post}")
      end
    end
  end

  defp create_post(_) do
    post = post_fixture()

    %{post: post}
  end
end
