defmodule Blog.Router do
  use Plug.Router

  alias Blog.{Post, Repo}

  import Ecto.Query

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"]
  )

  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, home_page())
  end

  get "/new" do
    send_resp(conn, 200, new_post_form())
  end

  post "/new" do
    attrs = %{
      "title" => conn.body_params["title"],
      "body" => conn.body_params["body"]
    }

    case %Post{} |> Post.changeset(attrs) |> Repo.insert() do
      {:ok, post} ->
        url = "/" <> String.replace(post.title, " ", "_")

        conn
        |> put_resp_header("location", url)
        |> send_resp(302, "")

      {:error, _changeset} ->
        send_resp(conn, 422, new_post_form())
    end
  end

  get "/:post_title" do
    title = String.replace(post_title, "_", " ")

    case Repo.get_by(Post, title: title) do
      nil ->
        send_resp(conn, 404, "Not found")

      %Post{} = post ->
        send_resp(conn, 200, show_post(post))
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp home_page do
    posts = recent_posts()

    links =
      posts
      |> Enum.map(fn %Post{title: title} ->
        url = "/" <> String.replace(title, " ", "_")
        "<li><a href=\"#{url}\">#{title}</a></li>"
      end)
      |> Enum.join("\n")

    """
    <!DOCTYPE html>
    <html>
      <head><title>Welcome to the blog</title></head>
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

  defp recent_posts do
    Repo.all(from(p in Post, order_by: [desc: p.inserted_at, desc: p.id], limit: 10))
  rescue
    DBConnection.OwnershipError -> []
  end

  defp show_post(%Post{title: title, body: body}) do
    """
    <!DOCTYPE html>
    <html>
      <head><title>#{title}</title></head>
      <body>
        <h1>#{title}</h1>
        <p>#{body}</p>
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
        <form action="/new" method="post">
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
