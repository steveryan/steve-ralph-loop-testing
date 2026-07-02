# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Blog.Repo.insert!(%Blog.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Blog.Content
alias Blog.Content.Post
alias Blog.Repo

# Sample posts for a fresh install. Seeds are idempotent: each post is keyed by
# its title, so running this script multiple times will not create duplicates.
sample_posts = [
  %{
    title: "Welcome to the Blog",
    body: """
    This is a tiny blog built with Elixir and the Phoenix framework.

    It stores posts in a local SQLite database and needs no accounts or
    authentication — just write a post, save it, and share the link.
    """
  },
  %{
    title: "Writing Your First Post",
    body: """
    Click "New Post" on the home page to create a post. Give it a title and a
    body, then save.

    Every post gets its own page at /posts/:id, so you can link to any post
    directly.
    """
  },
  %{
    title: "How It's Built",
    body: """
    The blog uses Phoenix controllers and server-rendered HTML views, Ecto for
    persistence, and SQLite for storage — no database server to run.

    Run `mix setup` to install dependencies and load these sample posts, then
    start the server with `mix phx.server`.
    """
  }
]

Enum.each(sample_posts, fn attrs ->
  case Repo.get_by(Post, title: attrs.title) do
    nil ->
      {:ok, _post} = Content.create_post(attrs)

    %Post{} ->
      :ok
  end
end)
