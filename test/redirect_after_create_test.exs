defmodule Blog.RedirectAfterCreateTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Blog.{Post, Repo}

  @opts Blog.Router.init([])

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "submitting the form redirects to the created post's url" do
    params = %{"title" => "Redirect Post", "body" => "Redirect body"}

    conn =
      conn(:post, "/new", params)
      |> Blog.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 302

    location = Plug.Conn.get_resp_header(conn, "location")
    assert location == ["/Redirect_Post"]

    post = Repo.get_by(Post, title: "Redirect Post")
    assert post
    assert post.body == "Redirect body"
  end
end
