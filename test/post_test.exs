defmodule Blog.PostTest do
  use ExUnit.Case

  alias Blog.Post
  alias Blog.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "persists a post with a string title and string body" do
    {:ok, post} =
      %Post{}
      |> Post.changeset(%{title: "First Post", body: "Hello, world"})
      |> Repo.insert()

    assert post.id

    fetched = Repo.get!(Post, post.id)
    assert fetched.title == "First Post"
    assert fetched.body == "Hello, world"
  end

  test "requires a title and body" do
    changeset = Post.changeset(%Post{}, %{})

    refute changeset.valid?
    assert %{title: ["can't be blank"], body: ["can't be blank"]} = errors_on(changeset)
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
