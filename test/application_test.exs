defmodule Blog.ApplicationTest do
  use ExUnit.Case, async: false

  test "the application and web server supervisor are running" do
    assert is_pid(Process.whereis(Blog.Supervisor))
    assert {:ok, _} = Application.ensure_all_started(:blog)
  end
end
