defmodule HotWeb.AuthLive.Login do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Empty placeholder for login page -->
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Login")
      |> assign(:current_page, :login)

    {:ok, socket}
  end
end
