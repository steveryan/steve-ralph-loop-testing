defmodule BlogWeb.PostLive.New do
  @moduledoc """
  Form for creating a new blog post.

  On a valid submission the post is persisted and the user is redirected to the
  new post's slug page. Invalid submissions re-render the form with errors.
  """
  use BlogWeb, :live_view

  alias Blog.Content
  alias Blog.Content.Post

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "New Post")
     |> assign_form(Content.change_post(%Post{}))}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      %Post{}
      |> Content.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    case Content.create_post(post_params) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully.")
         |> push_navigate(to: "/posts/#{post.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-2xl space-y-8">
        <header class="space-y-1">
          <h1 class="text-3xl font-semibold tracking-tight">New Post</h1>
          <p class="text-base-content/60">Write something worth reading. Markdown is supported.</p>
        </header>

        <.form for={@form} id="post-form" phx-change="validate" phx-submit="save" class="space-y-6">
          <.input field={@form[:title]} type="text" label="Title" placeholder="Post title" />
          <.input
            field={@form[:body]}
            type="textarea"
            label="Body"
            rows="12"
            placeholder="Write your post in Markdown…"
          />

          <div class="flex items-center gap-3">
            <.button variant="primary" phx-disable-with="Publishing…">Publish Post</.button>
            <.link navigate={~p"/"} class="btn btn-ghost">Cancel</.link>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
