defmodule Blog.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome to the blog")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
