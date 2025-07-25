defmodule HotWeb.SharedAuth do
  @moduledoc """
  Shared password authentication for Hot TV show tracking app.

  This module provides both a Plug for HTTP requests and an `on_mount` callback
  for LiveView sessions with password validation and session management.
  """

  import Plug.Conn
  import Phoenix.Controller

  use Phoenix.VerifiedRoutes,
    endpoint: HotWeb.Endpoint,
    router: HotWeb.Router,
    statics: HotWeb.static_paths()

  @doc """
  Plug function that checks authentication status.

  Checks session for authentication flag and redirects to login if not authenticated.
  """
  def init(opts), do: opts

  def call(conn, _opts) do
    if authenticated?(conn) do
      conn
    else
      conn
      |> store_return_path()
      |> redirect(to: ~p"/auth/login")
      |> halt()
    end
  end

  @doc """
  LiveView on_mount callback for session checking.

  Checks session for authentication flag and redirects to login if not authenticated.
  """
  def on_mount(:default, _params, session, socket) do
    if authenticated_session?(session) do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/auth/login")}
    end
  end

  @doc """
  Validates password against environment variable.

  Returns `:ok` if password is correct, `:error` if incorrect.
  Uses secure comparison to prevent timing attacks.
  """
  def validate_password(password) do
    shared_password = Application.get_env(:hot, :shared_password)

    if shared_password && Plug.Crypto.secure_compare(password, shared_password) do
      :ok
    else
      :error
    end
  end

  @doc """
  Authenticates user by validating password and setting session flag.

  Returns {:ok, conn} if password is valid, {:error, conn} if invalid.
  """
  def authenticate_user(conn, password) do
    case validate_password(password) do
      :ok ->
        {:ok, put_session(conn, :authenticated, true)}

      :error ->
        {:error, conn}
    end
  end

  @doc """
  Logs out user by clearing authentication session.
  """
  def logout_user(conn) do
    delete_session(conn, :authenticated)
  end

  defp authenticated?(conn) do
    get_session(conn, :authenticated) == true
  end

  defp authenticated_session?(session) do
    Map.get(session, "authenticated") == true
  end

  defp store_return_path(conn) do
    return_path = conn.request_path
    put_session(conn, :return_to, return_path)
  end
end
