defmodule HotWeb.CoreComponentsTest do
  use ExUnit.Case, async: true

  import HotWeb.CoreComponents
  import Phoenix.LiveViewTest

  # Helper to normalize whitespace for comparison
  defp normalize_html(html) do
    html
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  describe "linkify_text/1" do
    test "returns empty string for nil input" do
      assert linkify_text(nil) == ""
    end

    test "returns empty string for empty string input" do
      assert linkify_text("") == ""
    end

    test "returns plain text unchanged when no URLs present" do
      text = "This is just plain text with no links"
      result = linkify_text(text)

      assert normalize_html(rendered_to_string(result)) == text
    end

    test "converts multiple URLs in the same text" do
      text = "Check https://example.com and http://test.org for info"
      result = linkify_text(text)
      html = rendered_to_string(result)
      normalized = normalize_html(html)

      assert html =~ "<a href=\"https://example.com\""
      assert normalized =~ "> https://example.com </a>"
      assert html =~ "<a href=\"http://test.org\""
      assert normalized =~ "> http://test.org </a>"
      assert html =~ "Check"
      assert html =~ "and"
      assert html =~ "for info"
    end

    test "handles URLs with query parameters and fragments" do
      text = "Search at https://google.com/search?q=elixir#results"
      result = linkify_text(text)
      html = rendered_to_string(result)

      assert html =~ "<a href=\"https://google.com/search?q=elixir#results\""
      assert normalize_html(html) =~ "> https://google.com/search?q=elixir#results </a>"
    end

    test "handles URLs with ports" do
      text = "Local server at http://localhost:4000"
      result = linkify_text(text)
      html = rendered_to_string(result)

      assert html =~ "<a href=\"http://localhost:4000\""
      assert normalize_html(html) =~ "> http://localhost:4000 </a>"
    end

    test "escapes HTML in non-URL parts" do
      text = "Visit https://example.com <script>alert('xss')</script>"
      result = linkify_text(text)
      html = rendered_to_string(result)

      assert html =~ "<a href=\"https://example.com\""
      assert normalize_html(html) =~ "> https://example.com </a>"
      assert html =~ "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
      refute html =~ "<script>"
    end

    test "escapes HTML in URLs" do
      text = "Malicious URL: https://evil.com/path?param=<script>alert('xss')</script>"
      result = linkify_text(text)
      html = rendered_to_string(result)

      # The URL stops at certain characters and the script tag gets escaped as regular text
      assert html =~ "href=\"https://evil.com/path?param=\""
      assert normalize_html(html) =~ "> https://evil.com/path?param= </a>"
      assert html =~ "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
      refute html =~ "<script>"
    end

    test "handles URLs at the beginning of text" do
      text = "https://example.com is a great site"
      result = linkify_text(text)
      html = rendered_to_string(result)

      assert html =~ "<a href=\"https://example.com\""
      assert normalize_html(html) =~ "https://example.com </a> is a great site"
    end

    test "handles URLs at the end of text" do
      text = "Check out this site: https://example.com"
      result = linkify_text(text)
      html = rendered_to_string(result)

      assert normalize_html(html) =~ "Check out this site: <a href=\"https://example.com\""
      assert normalize_html(html) =~ "> https://example.com </a>"
    end

    test "handles URL surrounded by punctuation" do
      text = "Visit (https://example.com) for details."
      result = linkify_text(text)
      html = rendered_to_string(result)

      # The URL regex includes the closing parenthesis
      assert normalize_html(html) =~ "Visit ( <a href=\"https://example.com)\""
      assert normalize_html(html) =~ "> https://example.com) </a> for details."
    end

    test "does not linkify non-HTTP protocols" do
      text = "Send email to mailto:test@example.com or ftp://files.example.com"
      result = linkify_text(text)
      html = rendered_to_string(result)

      refute html =~ "<a href="
      assert normalize_html(html) == text
    end

    test "handles text with newlines and URLs" do
      text = "Line 1 with https://example.com\nLine 2 with http://test.org"
      result = linkify_text(text)
      html = rendered_to_string(result)

      assert html =~ "<a href=\"https://example.com\""
      assert html =~ "<a href=\"http://test.org\""
      assert html =~ "Line 1 with"
      assert html =~ "Line 2 with"
    end
  end
end
