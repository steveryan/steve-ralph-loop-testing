defmodule Blog.Content do
  @moduledoc """
  The Content context: managing blog posts.
  """

  import Ecto.Query, warn: false
  alias Blog.Repo
  alias Blog.Content.Post

  @doc """
  Returns the list of posts, newest first.
  """
  def list_posts do
    Post
    |> order_by(desc: :inserted_at, desc: :id)
    |> Repo.all()
  end

  @doc """
  Gets a single post by id.

  Raises `Ecto.NoResultsError` if the post does not exist.
  """
  def get_post!(id), do: Repo.get!(Post, id)

  @doc """
  Gets a single post by its slug.

  Raises `Ecto.NoResultsError` if the post does not exist.
  """
  def get_post_by_slug!(slug), do: Repo.get_by!(Post, slug: slug)

  @doc """
  Creates a post.

  The slug is derived from the title when not provided. When the derived slug
  collides with an existing post, a numeric suffix is appended so that posts
  with duplicate titles still receive distinct, unique slugs.
  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> ensure_unique_slug()
    |> Repo.insert()
  end

  @doc """
  Returns a changeset for tracking post changes.
  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  defp ensure_unique_slug(changeset) do
    case Ecto.Changeset.get_change(changeset, :slug) do
      nil -> changeset
      slug -> Ecto.Changeset.put_change(changeset, :slug, available_slug(slug))
    end
  end

  defp available_slug(base) do
    if slug_taken?(base), do: next_available_slug(base, 2), else: base
  end

  defp next_available_slug(base, n) do
    candidate = "#{base}-#{n}"
    if slug_taken?(candidate), do: next_available_slug(base, n + 1), else: candidate
  end

  defp slug_taken?(slug) do
    Repo.exists?(from p in Post, where: p.slug == ^slug)
  end
end
