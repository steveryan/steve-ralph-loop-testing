defmodule Blog.ShowPostTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Blog.{Post, Repo}

  @opts Blog.Router.init([])

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "navigating to /test_post shows the post titled 'test post'" do
    {:ok, _post} =
      %Post{}
      |> Post.changeset(%{title: "test post", body: "the body of the test post"})
      |> Repo.insert()

    conn = conn(:get, "/test_post") |> Blog.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body =~ "test post"
    assert conn.resp_body =~ "the body of the test post"
  end
end
