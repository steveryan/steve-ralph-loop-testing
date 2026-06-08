defmodule Blog.Router do
  @moduledoc false

  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Blog server is running")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
