defmodule Blog.HomeRecentPostsTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Blog.{Post, Repo}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "home page lists the ten most recent posts, newest first, under Recent Posts" do
    for n <- 1..12 do
      {:ok, _post} =
        %Post{}
        |> Post.changeset(%{title: "Post #{n}", body: "Body #{n}"})
        |> Repo.insert()
    end

    conn = conn(:get, "/")
    conn = Blog.Router.call(conn, Blog.Router.init([]))

    assert conn.status == 200
    assert conn.resp_body =~ "Recent Posts"

    # The ten most recent posts (Post 12 down to Post 3) should be present.
    for n <- 3..12 do
      assert conn.resp_body =~ "/Post_#{n}"
      assert conn.resp_body =~ "Post #{n}"
    end

    # The two oldest posts should not be present.
    refute conn.resp_body =~ ">Post 1<"
    refute conn.resp_body =~ ">Post 2<"

    # Most recent should appear before less recent (descending order).
    assert :binary.match(conn.resp_body, "Post 12") |> elem(0) <
             (:binary.match(conn.resp_body, "Post 3") |> elem(0))
  end
end
