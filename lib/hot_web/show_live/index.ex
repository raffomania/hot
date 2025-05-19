defmodule HotWeb.ShowLive.Index do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Shows
    </.header>

    <.table
      id="shows"
      rows={@streams.shows}
      row_click={fn {_id, show} -> JS.navigate(~p"/shows/#{show}") end}
    >
      <:col :let={{_id, show}} label="Id">{show.id}</:col>

      <:action :let={{_id, show}}>
        <div class="sr-only">
          <.link navigate={~p"/shows/#{show}"}>Show</.link>
        </div>
      </:action>
    </.table>
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

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Show")
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Shows")
    |> assign(:show, nil)
  end

  @impl true
  def handle_info({HotWeb.ShowLive.FormComponent, {:saved, show}}, socket) do
    {:noreply, stream_insert(socket, :shows, show)}
  end
end
