defmodule HotWeb.ShowLive.Index do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.link :for={{_id, show} <- @streams.shows} navigate={~p"/shows/#{show.id}"}>
      <h2 class="mb-4 font-bold">
        {show.title}
      </h2>
    </.link>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :shows, Ash.read!(Hot.Trakt.Show))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Shows")
  end
end
