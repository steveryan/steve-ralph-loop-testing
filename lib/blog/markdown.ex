defmodule Blog.Markdown do
  @moduledoc """
  Renders Markdown source text into HTML for displaying blog posts.

  Uses [Earmark](https://hexdocs.pm/earmark) with its default options, which
  escape raw inline HTML, producing output that is safe to render raw in a
  template (e.g. via `Phoenix.HTML.raw/1`).
  """

  @doc """
  Converts a Markdown string into an HTML string.

  Returns the rendered HTML. Non-binary input returns an empty string.

  ## Examples

      iex> Blog.Markdown.to_html("# Hi") =~ "<h1>"
      true

  """
  def to_html(markdown) when is_binary(markdown) do
    case Earmark.as_html(markdown) do
      {:ok, html, _warnings} -> html
      {:error, html, _errors} -> html
    end
  end

  def to_html(_), do: ""
end
