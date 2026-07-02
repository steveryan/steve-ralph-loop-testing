defmodule BlogWeb.PostLive.Show do
  @moduledoc """
  Displays a single blog post, looked up by its slug.

  The post body is stored as Markdown and rendered to sanitized HTML via
  `Blog.Markdown.to_html/1`. An unknown slug raises `Ecto.NoResultsError`,
  which Phoenix renders as a 404.
  """
  use BlogWeb, :live_view

  alias Blog.Content

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    post = Content.get_post_by_slug!(slug)

    {:noreply,
     socket
     |> assign(:page_title, post.title)
     |> assign(:post, post)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <article class="mx-auto max-w-2xl space-y-8">
        <header class="space-y-2">
          <.link navigate={~p"/"} class="text-sm text-base-content/60 hover:text-primary">
            ← Back to posts
          </.link>
          <h1 class="text-4xl font-semibold tracking-tight">{@post.title}</h1>
          <p class="text-sm text-base-content/60">
            {Calendar.strftime(@post.inserted_at, "%B %d, %Y")}
          </p>
        </header>

        <div class="prose prose-lg max-w-none">
          {raw(Blog.Markdown.to_html(@post.body))}
        </div>
      </article>
    </Layouts.app>
    """
  end
end
