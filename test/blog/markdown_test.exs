defmodule Blog.MarkdownTest do
  use ExUnit.Case, async: true

  alias Blog.Markdown

  describe "to_html/1" do
    test "converts a Markdown heading to an <h1> element" do
      assert Markdown.to_html("# Hi") =~ "<h1>"
    end

    test "converts plain text to a paragraph" do
      html = Markdown.to_html("Just plain text")

      assert html =~ "<p>"
      assert html =~ "Just plain text"
    end

    test "renders inline emphasis as HTML" do
      assert Markdown.to_html("**bold**") =~ "<strong>"
    end

    test "returns an empty string for non-binary input" do
      assert Markdown.to_html(nil) == ""
    end
  end
end
