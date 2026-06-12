defmodule Blog.RouterTest do
  use ExUnit.Case, async: true
  import Plug.Test

  @opts Blog.Router.init([])

  test "the application starts and the router responds" do
    conn = conn(:get, "/") |> Blog.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "the webserver shows the welcome page by default" do
    conn = conn(:get, "/") |> Blog.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body =~ "Welcome to the blog"
  end
end
