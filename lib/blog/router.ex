defmodule Blog.Router do
  @moduledoc false

  use Plug.Router

  alias Blog.{Post, Repo}

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded]
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome to the blog")
  end

  get "/new" do
    send_resp(conn, 200, new_post_form())
  end

  post "/new" do
    params = conn.params

    changeset =
      Post.changeset(%Post{}, %{
        "title" => params["title"],
        "body" => params["body"]
      })

    case Repo.insert(changeset) do
      {:ok, _post} ->
        send_resp(conn, 200, "Post created")

      {:error, _changeset} ->
        send_resp(conn, 422, new_post_form())
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp new_post_form do
    """
    <!DOCTYPE html>
    <html>
      <head><title>New Post</title></head>
      <body>
        <h1>New Post</h1>
        <form method="post" action="/new">
          <label for="title">Title</label>
          <input type="text" id="title" name="title" />
          <label for="body">Body</label>
          <textarea id="body" name="body"></textarea>
          <button type="submit">Create Post</button>
        </form>
      </body>
    </html>
    """
  end
end
