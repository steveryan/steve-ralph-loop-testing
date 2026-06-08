defmodule Blog.Router do
  @moduledoc false

  use Plug.Router

  import Ecto.Query, only: [from: 2]

  alias Blog.{Post, Repo}

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded]
  plug :dispatch

  get "/" do
    send_resp(conn, 200, home_page())
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

  get "/:post_title" do
    title = String.replace(post_title, "_", " ")

    case Repo.get_by(Post, title: title) do
      nil ->
        send_resp(conn, 404, "Not found")

      post ->
        send_resp(conn, 200, show_post(post))
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp home_page do
    posts =
      Repo.all(
        from p in Post,
          order_by: [desc: p.inserted_at, desc: p.id],
          limit: 10
      )

    links =
      posts
      |> Enum.map(fn post ->
        slug = String.replace(post.title, " ", "_")
        "<li><a href=\"/#{slug}\">#{post.title}</a></li>"
      end)
      |> Enum.join("\n")

    """
    <!DOCTYPE html>
    <html>
      <head><title>Blog</title></head>
      <body>
        <h1>Welcome to the blog</h1>
        <h2>Recent Posts</h2>
        <ul>
          #{links}
        </ul>
      </body>
    </html>
    """
  end

  defp show_post(post) do
    """
    <!DOCTYPE html>
    <html>
      <head><title>#{post.title}</title></head>
      <body>
        <h1>#{post.title}</h1>
        <p>#{post.body}</p>
      </body>
    </html>
    """
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
