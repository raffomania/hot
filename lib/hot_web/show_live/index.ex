defmodule HotWeb.ShowLive.Index do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.link :for={{_id, episode} <- @streams.episodes} navigate={~p"/shows/#{episode.season.show.id}"}>
      <h2 class="mt-4 font-bold">
        {episode.season.show.title} S{episode.season.number} E{episode.number}
      </h2>
      <p>{episode.last_watched_at}</p>
    </.link>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    episodes =
      Hot.Trakt.Episode
      |> Ash.Query.load(season: [:show])
      |> Ash.Query.sort(last_watched_at: :desc)
      |> Ash.read!()

    {:ok, stream(socket, :episodes, episodes)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Recently Watched")
  end
end
