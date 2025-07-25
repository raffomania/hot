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

  describe "password validation" do
    test "returns :ok for correct password" do
      Application.put_env(:hot, :shared_password, "test_password_123")
      assert HotWeb.SharedAuth.validate_password("test_password_123") == :ok
    end

    test "returns :error for incorrect password" do
      Application.put_env(:hot, :shared_password, "test_password_123")
      assert HotWeb.SharedAuth.validate_password("wrong_password") == :error
    end

    test "returns :error when no config is set" do
      Application.put_env(:hot, :shared_password, nil)
      assert HotWeb.SharedAuth.validate_password("any_password") == :error
    end
  end

  describe "authenticated user access" do
    test "authenticated user can access protected routes", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:authenticated, true)
        |> get(~p"/shows")

      assert html_response(conn, 200)
    end

    test "authenticated user can access protected LiveView routes", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:authenticated, true)

      assert {:ok, _view, _html} = live(conn, ~p"/shows")
    end
  end

  describe "session management" do
    test "authenticate_user sets session flag with valid password", %{conn: conn} do
      Application.put_env(:hot, :shared_password, "test_password_123")
      conn = init_test_session(conn, %{})

      assert {:ok, authenticated_conn} =
               HotWeb.SharedAuth.authenticate_user(conn, "test_password_123")

      assert get_session(authenticated_conn, :authenticated) == true
    end

    test "authenticate_user returns error with invalid password", %{conn: conn} do
      Application.put_env(:hot, :shared_password, "test_password_123")
      conn = init_test_session(conn, %{})

      assert {:error, error_conn} = HotWeb.SharedAuth.authenticate_user(conn, "wrong_password")
      assert get_session(error_conn, :authenticated) == nil
    end

    test "logout_user clears session flag", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:authenticated, true)
        |> HotWeb.SharedAuth.logout_user()

      assert get_session(conn, :authenticated) == nil
    end
  end

  describe "on_mount callback behavior" do
    test "allows access for authenticated session" do
      session = %{"authenticated" => true}
      socket = %Phoenix.LiveView.Socket{}

      assert {:cont, ^socket} = HotWeb.SharedAuth.on_mount(:default, %{}, session, socket)
    end

    test "redirects for unauthenticated session" do
      session = %{}
      socket = %Phoenix.LiveView.Socket{}

      assert {:halt, redirect_socket} = HotWeb.SharedAuth.on_mount(:default, %{}, session, socket)
      assert {:redirect, %{to: "/auth/login"}} = redirect_socket.redirected
    end
  end

  describe "session persistence" do
    test "session persists across multiple requests", %{conn: conn} do
      Application.put_env(:hot, :shared_password, "test_password_123")

      # First request - authenticate
      conn = init_test_session(conn, %{})
      {:ok, authenticated_conn} = HotWeb.SharedAuth.authenticate_user(conn, "test_password_123")

      # Second request - should still be authenticated
      conn = get(authenticated_conn, ~p"/shows")

      assert html_response(conn, 200)
    end
  end
end
