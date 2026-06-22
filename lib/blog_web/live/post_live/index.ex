defmodule BlogWeb.PostLive.Index do
  @moduledoc """
  Lists all blog posts, newest first, linking each title to its slug page.
  """
  use BlogWeb, :live_view

  alias Blog.Content

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Posts")
     |> stream(:posts, Content.list_posts())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-8">
        <header class="space-y-1">
          <h1 class="text-3xl font-semibold tracking-tight">Posts</h1>
          <p class="text-base-content/60">The latest writing, newest first.</p>
        </header>

        <ul id="posts" phx-update="stream" class="divide-y divide-base-200">
          <li id="posts-empty" class="hidden only:block py-10 text-center text-base-content/60">
            No posts yet.
          </li>
          <li :for={{id, post} <- @streams.posts} id={id} class="group py-5">
            <.link
              navigate={"/posts/#{post.slug}"}
              class="text-xl font-medium text-base-content transition-colors group-hover:text-primary"
            >
              {post.title}
            </.link>
            <p class="mt-1 text-sm text-base-content/60">
              {Calendar.strftime(post.inserted_at, "%B %d, %Y")}
            </p>
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end
end
