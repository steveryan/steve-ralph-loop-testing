defmodule Blog.PostShowPageTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Blog.{Post, Repo}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "navigating to /test_post shows the post titled \"test post\"" do
    {:ok, _post} =
      %Post{}
      |> Post.changeset(%{title: "test post", body: "This is the test post body"})
      |> Repo.insert()

    conn = conn(:get, "/test_post")
    conn = Blog.Router.call(conn, Blog.Router.init([]))

    assert conn.status == 200
    assert conn.resp_body =~ "test post"
    assert conn.resp_body =~ "This is the test post body"
  end
end
