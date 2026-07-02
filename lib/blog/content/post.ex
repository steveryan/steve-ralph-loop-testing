defmodule Blog.Content.Post do
  @moduledoc """
  Schema and changeset for a blog post.

  A post has a human-readable `slug` derived from its `title` when one is not
  supplied. Slugs are unique across all posts.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :slug, :string
    field :body, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset for a post.

  Requires `title` and `body`. When `slug` is blank it is derived from the
  title via `slugify/1`. Slug uniqueness is enforced via a unique constraint
  on the `posts.slug` index.
  """
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :slug, :body])
    |> validate_required([:title, :body])
    |> maybe_generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug)
  end

  defp maybe_generate_slug(changeset) do
    case get_field(changeset, :slug) do
      slug when is_binary(slug) and slug != "" ->
        changeset

      _ ->
        case get_field(changeset, :title) do
          title when is_binary(title) ->
            put_change(changeset, :slug, slugify(title))

          _ ->
            changeset
        end
    end
  end

  @doc """
  Converts a string into a lowercase, hyphenated, alphanumeric slug.

  ## Examples

      iex> Blog.Content.Post.slugify("My First Post!")
      "my-first-post"

  """
  def slugify(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/[\s_]+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end
end
