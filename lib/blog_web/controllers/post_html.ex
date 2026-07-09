defmodule BlogWeb.PostHTML do
  use BlogWeb, :html

  embed_templates "post_html/*"

  @doc """
  Renders a post form.

  The form is defined in the template at
  post_html/post_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def post_form(assigns)

  @doc """
  Returns a human-friendly label for how many posts are listed.

  The count is derived from the already-loaded `posts` list so the index
  page does not need an additional query.
  """
  def post_count_label(posts) do
    case length(posts) do
      0 -> "No posts yet"
      1 -> "1 post"
      count -> "#{count} posts"
    end
  end
end
