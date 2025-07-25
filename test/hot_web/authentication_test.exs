defmodule HotWeb.AuthenticationTest do
  use HotWeb.ConnCase
  import Phoenix.LiveViewTest

  use Phoenix.VerifiedRoutes,
    endpoint: HotWeb.Endpoint,
    router: HotWeb.Router,
    statics: HotWeb.static_paths()

  describe "protected routes without authentication" do
    @protected_routes [
      "/shows",
      "/shows/1",
      "/board"
    ]

    for route <- @protected_routes do
      test "GET #{route} redirects to login", %{conn: conn} do
        conn = get(conn, unquote(route))
        assert redirected_to(conn) == ~p"/auth/login"
      end
    end
  end

  describe "protected LiveView routes without authentication" do
    @protected_liveview_routes [
      "/shows",
      "/shows/1",
      "/board"
    ]

    for route <- @protected_liveview_routes do
      test "LiveView #{route} redirects to login", %{conn: conn} do
        assert {:error, {:redirect, %{to: "/auth/login"}}} =
                 live(conn, unquote(route))
      end
    end
  end

  describe "login page accessibility" do
    test "GET /auth/login is accessible without authentication", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")
      assert html_response(conn, 200)
    end
  end

  describe "return path preservation" do
    @return_path_routes [
      "/shows",
      "/shows/123",
      "/board"
    ]

    for route <- @return_path_routes do
      test "stores return path when redirecting from #{route}", %{conn: conn} do
        conn = get(conn, unquote(route))
        assert get_session(conn, :return_to) == unquote(route)
      end
    end
  end
end
