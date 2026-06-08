defmodule Blog.NewPostPageTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Blog.{Post, Repo}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "the /new page is reachable and contains the form elements" do
    conn = conn(:get, "/new")
    conn = Blog.Router.call(conn, Blog.Router.init([]))

    assert conn.status == 200
    assert conn.resp_body =~ ~s(<form method="post" action="/new")
    assert conn.resp_body =~ ~s(name="title")
    assert conn.resp_body =~ ~s(name="body")
    assert conn.resp_body =~ "Create Post"
  end

  test "submitting the form persists the post" do
    conn =
      conn(:post, "/new", %{"title" => "Persisted Title", "body" => "Persisted body text"})

    conn = Blog.Router.call(conn, Blog.Router.init([]))

    assert conn.status in [200, 302]

    post = Repo.get_by(Post, title: "Persisted Title")
    assert post
    assert post.body == "Persisted body text"
  end
end
