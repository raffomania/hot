==> ash
Compiling 531 files (.ex)
Compiling lib/ash/reactor/reactor.ex (it's taking more than 10s)
Generated ash app
==> ash_sql
Compiling 13 files (.ex)
Generated ash_sql app
==> cc_precompiler
Compiling 3 files (.ex)
Generated cc_precompiler app
==> exqlite
Compiling 12 files (.ex)
Generated exqlite app
==> ecto_sqlite3
Compiling 5 files (.ex)
Generated ecto_sqlite3 app
==> ash_sqlite
Compiling 26 files (.ex)
Generated ash_sqlite app
==> tailwind
Compiling 3 files (.ex)
Generated tailwind app
==> websock
Compiling 1 file (.ex)
Generated websock app
==> bandit
Compiling 54 files (.ex)
Generated bandit app
==> swoosh
Compiling 53 files (.ex)
Generated swoosh app
==> websock_adapter
Compiling 4 files (.ex)
Generated websock_adapter app
==> phoenix
Compiling 71 files (.ex)
Generated phoenix app
==> phoenix_live_reload
Compiling 5 files (.ex)
Generated phoenix_live_reload app
==> phoenix_live_view
Compiling 48 files (.ex)
Generated phoenix_live_view app
==> live_debugger
Compiling 76 files (.ex)
Generated live_debugger app
==> ash_phoenix
Compiling 34 files (.ex)
Generated ash_phoenix app
==> ash_admin
Compiling 39 files (.ex)
Generated ash_admin app
==> phoenix_live_dashboard
Compiling 36 files (.ex)
Generated phoenix_live_dashboard app
defmodule HotWeb.AuthControllerTest do
  use HotWeb.ConnCase

  use Phoenix.VerifiedRoutes,
    endpoint: HotWeb.Endpoint,
    router: HotWeb.Router,
    statics: HotWeb.static_paths()

  describe "GET /auth/login" do
    test "renders login form when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")

      assert html_response(conn, 200)
      assert html = response(conn, 200)
      assert html =~ "(｡◕‿‿◕｡)"
      assert html =~ "Enter shared password"
      assert html =~ "Sign in"
      assert html =~ "type=\"password\""
      assert html =~ "name=\"password\""
    end

    test "redirects to return path when already authenticated", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:authenticated, true)
        |> put_session(:return_to, "/shows/123")
        |> get(~p"/auth/login")

      assert redirected_to(conn) == "/shows/123"
    end

    test "redirects to default path when already authenticated with no return path", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:authenticated, true)
        |> get(~p"/auth/login")

      assert redirected_to(conn) == "/shows"
    end

    test "does not show logout button when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")

      html = response(conn, 200)
      refute html =~ "Sign out"
    end
  end

  describe "POST /auth/login" do
    test "successful authentication with correct password redirects to default", %{conn: conn} do
      Application.put_env(:hot, :shared_password, "test_password_123")

      conn =
        conn
        |> init_test_session(%{})
        |> post(~p"/auth/login", %{"password" => "test_password_123"})

      assert get_session(conn, :authenticated) == true
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Login successful!"
      assert redirected_to(conn) == "/shows"
    end

    test "successful authentication with correct password redirects to return path", %{conn: conn} do
      Application.put_env(:hot, :shared_password, "test_password_123")

      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:return_to, "/shows/123")
        |> post(~p"/auth/login", %{"password" => "test_password_123"})

      assert get_session(conn, :authenticated) == true
      # Should be cleared after successful login
      assert get_session(conn, :return_to) == nil
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Login successful!"
      assert redirected_to(conn) == "/shows/123"
    end

    test "failed authentication with incorrect password shows error", %{conn: conn} do
      Application.put_env(:hot, :shared_password, "test_password_123")

      conn =
        conn
        |> init_test_session(%{})
        |> post(~p"/auth/login", %{"password" => "wrong_password"})

      assert get_session(conn, :authenticated) == nil
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid password. Who are you?"
      assert html_response(conn, 200)

      html = response(conn, 200)
      assert html =~ "(｡◕‿‿◕｡)"
    end

    test "failed authentication when no config is set", %{conn: conn} do
      Application.put_env(:hot, :shared_password, nil)

      conn =
        conn
        |> init_test_session(%{})
        |> post(~p"/auth/login", %{"password" => "any_password"})

      assert get_session(conn, :authenticated) == nil
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid password. Who are you?"
      assert html_response(conn, 200)
    end
  end

  describe "DELETE /auth/logout" do
    test "logs out authenticated user and redirects to login", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> put_session(:authenticated, true)
        |> delete(~p"/auth/logout")

      assert get_session(conn, :authenticated) == nil
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "You have been logged out."
      assert redirected_to(conn) == "/auth/login"
    end

    test "handles logout when user is not authenticated", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> delete(~p"/auth/logout")

      assert get_session(conn, :authenticated) == nil
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "You have been logged out."
      assert redirected_to(conn) == "/auth/login"
    end
  end

  describe "form rendering and validation" do
    test "login form has required password field", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")

      html = response(conn, 200)
      assert html =~ "required"
      assert html =~ "type=\"password\""
    end

    test "login form posts to correct endpoint", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")

      html = response(conn, 200)
      assert html =~ "action=\"/auth/login\""
      assert html =~ "method=\"post\""
    end

    test "login form includes CSRF protection", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")

      html = response(conn, 200)
      assert html =~ "_csrf_token"
    end
  end

  describe "session management" do
    test "preserves session data across requests", %{conn: conn} do
      Application.put_env(:hot, :shared_password, "test_password_123")

      # First request - authenticate
      conn =
        conn
        |> init_test_session(%{})
        |> post(~p"/auth/login", %{"password" => "test_password_123"})

      assert get_session(conn, :authenticated) == true

      # Second request - should still be authenticated when accessing protected routes
      conn = get(conn, ~p"/shows")
      assert html_response(conn, 200)
    end
  end

  describe "page metadata" do
    test "sets correct page title", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")

      html = response(conn, 200)
      assert html =~ "Login"
      assert html =~ "<title"
    end
  end
end
