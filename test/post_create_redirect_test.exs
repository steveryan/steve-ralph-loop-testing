defmodule Blog.PostCreateRedirectTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Blog.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "creating a post redirects to that post's url" do
    conn =
      conn(:post, "/new", %{"title" => "Redirect Me", "body" => "Some body text"})

    conn = Blog.Router.call(conn, Blog.Router.init([]))

    assert conn.status == 302

    location =
      conn.resp_headers
      |> Enum.into(%{})
      |> Map.get("location")

    assert location == "/Redirect_Me"
  end
end
