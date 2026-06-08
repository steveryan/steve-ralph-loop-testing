defmodule Blog.WelcomePageTest do
  use ExUnit.Case, async: true
  import Plug.Test

  alias Blog.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "the home page shows the welcome message by default" do
    conn = conn(:get, "/")
    conn = Blog.Router.call(conn, Blog.Router.init([]))

    assert conn.status == 200
    assert conn.resp_body =~ "Welcome to the blog"
  end
end
