defmodule Blog.WebserverTest do
  use ExUnit.Case, async: false

  @port System.get_env("PORT", "4000") |> String.to_integer()

  test "the running webserver can be accessed over HTTP" do
    {:ok, socket} =
      :gen_tcp.connect(~c"localhost", @port, [:binary, active: false, packet: :raw], 2000)

    request = "GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
    :ok = :gen_tcp.send(socket, request)

    {:ok, response} = :gen_tcp.recv(socket, 0, 2000)
    :gen_tcp.close(socket)

    assert response =~ "HTTP/1.1 200"
  end
end
