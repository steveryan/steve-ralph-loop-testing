defmodule Blog.WebServerTest do
  use ExUnit.Case, async: false

  test "the web server is reachable over HTTP" do
    {:ok, _} = Application.ensure_all_started(:blog)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Blog.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Blog.Repo, {:shared, self()})

    port = Application.get_env(:blog, :port)

    {:ok, socket} =
      :gen_tcp.connect(~c"localhost", port, [:binary, active: false, packet: :raw], 5000)

    :ok = :gen_tcp.send(socket, "GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n")
    {:ok, response} = :gen_tcp.recv(socket, 0, 5000)
    :gen_tcp.close(socket)

    assert response =~ "HTTP/1.1 200"
  end
end
