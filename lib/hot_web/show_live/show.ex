defmodule HotWeb.ShowLive.Show do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@show.title}
    </.header>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:show, Ash.get!(Hot.Trakt.Show, id))}
  end

  defp page_title(:show), do: "Show Show"
end
