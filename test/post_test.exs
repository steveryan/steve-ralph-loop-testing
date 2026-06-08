defmodule Blog.PostTest do
  use ExUnit.Case, async: false

  alias Blog.{Post, Repo}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "a post with a title and body can be persisted and read back" do
    {:ok, post} =
      %Post{}
      |> Post.changeset(%{title: "My First Post", body: "Hello, world!"})
      |> Repo.insert()

    assert post.id

    fetched = Repo.get!(Post, post.id)
    assert fetched.title == "My First Post"
    assert fetched.body == "Hello, world!"
  end

  test "a post requires a title and a body" do
    changeset = Post.changeset(%Post{}, %{})

    refute changeset.valid?
    assert %{title: ["can't be blank"], body: ["can't be blank"]} = errors_on(changeset)
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r/%{(\w+)}/, msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
