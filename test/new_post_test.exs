defmodule Blog.NewPostTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Blog.{Post, Repo}

  @opts Blog.Router.init([])

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "the /new page is reachable and contains the form elements" do
    conn = conn(:get, "/new") |> Blog.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body =~ ~s(<form action="/new" method="post">)
    assert conn.resp_body =~ ~s(name="title")
    assert conn.resp_body =~ ~s(name="body")
    assert conn.resp_body =~ "Create Post"
  end

  test "submitting the form persists the post" do
    params = %{"title" => "Submitted Post", "body" => "Submitted body"}

    conn =
      conn(:post, "/new", params)
      |> Blog.Router.call(@opts)

    assert conn.state == :sent

    post = Repo.get_by(Post, title: "Submitted Post")
    assert post
    assert post.body == "Submitted body"
  end
end
