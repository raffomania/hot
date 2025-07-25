defmodule HotWeb.SharedAuth do
  @moduledoc """
  Shared password authentication for Hot TV show tracking app.

  This module provides both a Plug for HTTP requests and an `on_mount` callback
  for LiveView sessions. Currently, this always denies access and redirects
  to the login page.
  """

  import Plug.Conn
  import Phoenix.Controller

  use Phoenix.VerifiedRoutes,
    endpoint: HotWeb.Endpoint,
    router: HotWeb.Router,
    statics: HotWeb.static_paths()

  @doc """
  Plug function that checks authentication status.

  Currently, this always denies access and redirects to login.
  """
  def init(opts), do: opts

  def call(conn, _opts) do
    # Always deny access currently
    conn
    |> store_return_path()
    |> redirect(to: ~p"/auth/login")
    |> halt()
  end

  @doc """
  LiveView on_mount callback for session checking.

  Currently, this always denies access and redirects to login.
  """
  def on_mount(:default, _params, _session, socket) do
    # Always deny access currently
    {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/auth/login")}
  end

  defp store_return_path(conn) do
    return_path = conn.request_path
    put_session(conn, :return_to, return_path)
  end
end
