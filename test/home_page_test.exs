defmodule Blog.HomePageTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Blog.{Post, Repo}

  @opts Blog.Router.init([])

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  defp insert_post(title) do
    {:ok, post} =
      %Post{}
      |> Post.changeset(%{title: title, body: "body of #{title}"})
      |> Repo.insert()

    post
  end

  test "home page lists the ten most recent posts under a Recent Posts subheading" do
    for n <- 1..12 do
      insert_post("post #{n}")
    end

    conn = conn(:get, "/") |> Blog.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body =~ "Recent Posts"
    assert conn.resp_body =~ "Welcome to the blog"

    # Most recent ten (post 3..12) appear; the two oldest (1 and 2) do not.
    for n <- 3..12 do
      assert conn.resp_body =~ "post #{n}"
      assert conn.resp_body =~ ~s(href="/post_#{n}")
    end

    refute conn.resp_body =~ ">post 1<"
    refute conn.resp_body =~ ">post 2<"
  end

  test "recent posts are listed most recent first" do
    insert_post("oldest")
    insert_post("middle")
    insert_post("newest")

    conn = conn(:get, "/") |> Blog.Router.call(@opts)

    newest_idx = :binary.match(conn.resp_body, "newest") |> elem(0)
    middle_idx = :binary.match(conn.resp_body, "middle") |> elem(0)
    oldest_idx = :binary.match(conn.resp_body, "oldest") |> elem(0)

    assert newest_idx < middle_idx
    assert middle_idx < oldest_idx
  end
end
