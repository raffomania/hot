defmodule HotWeb.AuthController do
  use HotWeb, :controller

  def login(conn, _params) do
    # Check if user is already authenticated
    if get_session(conn, :authenticated) do
      # User is already logged in, redirect to return path or default
      return_to = get_session(conn, :return_to) || "/shows"
      redirect(conn, to: return_to)
    else
      # Render login page
      render(conn, :login, page_title: "Login", current_page: :login)
    end
  end

  def authenticate(conn, %{"password" => password}) do
    case HotWeb.SharedAuth.authenticate_user(conn, password) do
      {:ok, authenticated_conn} ->
        return_to = get_session(authenticated_conn, :return_to) || "/shows"

        authenticated_conn
        |> delete_session(:return_to)
        |> redirect(to: return_to)

      {:error, _conn} ->
        conn
        |> put_flash(:error, "Invalid password. Who are you?")
        |> render(:login, page_title: "Login", current_page: :login)
    end
  end

  def logout(conn, _params) do
    conn
    |> HotWeb.SharedAuth.logout_user()
    |> redirect(to: "/")
  end
end
