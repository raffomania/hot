defmodule HotWeb.ShowLive.Index do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
      <%= for {_id, episode} <- @streams.episodes do %>
        <div class="text-right">
          <p>{format_date_relative(episode.last_watched_at)}</p>
          <p class="text-neutral-500">{format_date_absolute(episode.last_watched_at)}</p>
        </div>
        <div class="col-span-2">
          <.link navigate={~p"/shows/#{episode.season.show.id}"}>
            <h3 class="underline">
              {episode.season.show.title}
            </h3>
          </.link>
          <p>
            S{format_season_episode_number(episode.season.number)}E{format_season_episode_number(
              episode.number
            )}
          </p>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    episodes =
      Hot.Trakt.Episode
      |> Ash.Query.load(season: [:show])
      |> Ash.Query.sort(last_watched_at: :desc)
      |> Ash.Query.limit(5)
      |> Ash.read!()

    socket =
      socket
      |> stream(:episodes, episodes)
      |> assign(:page_title, "Watched Log")

    {:ok, socket}
  end

  def format_date_relative(now \\ DateTime.utc_now(), later) do
    days_diff = DateTime.diff(now, later, :day)

    cond do
      days_diff <= 0 -> "in the future???"
      days_diff <= 1 -> "today"
      days_diff <= 7 -> "#{days_diff} days ago"
      days_diff <= 14 -> "1 week ago"
      true -> "#{div(days_diff, 7)} weeks ago"
    end
  end

  def format_date_absolute(date) do
    Calendar.strftime(date, "%d.%m.%y")
  end

  def format_season_episode_number(n) do
    n |> to_string() |> String.pad_leading(2, "0")
  end
end
