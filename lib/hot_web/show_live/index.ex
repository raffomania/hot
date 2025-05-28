defmodule HotWeb.ShowLive.Index do
  use HotWeb, :live_view
  require Ash.Expr

  @impl true
  def render(assigns) do
    ~H"""
    <h2 class="mb-8 font-bold text-center">Watch Log</h2>
    <div class="grid grid-cols-2 gap-4">
      <%= for {_id, episode} <- @streams.episodes do %>
        <div class="text-right">
          <p>{format_date_relative(episode.last_watched_at)}</p>
          <p class="text-neutral-500">{format_date_absolute(episode.last_watched_at)}</p>
        </div>
        <div class="col-span-1">
          <.link navigate={~p"/shows/#{episode.season.show.id}"} class="underline">
            {episode.season.show.title}
          </.link>
          <p>
            S{format_season_episode_number(episode.season.number)}E{format_season_episode_number(
              episode.number
            )}
          </p>
        </div>
      <% end %>
    </div>
    <h2 class="mt-16 mb-8 font-bold text-center">All shows</h2>
    <div class="grid grid-cols-2 gap-8">
      <div
        :for={year <- Map.keys(@other_shows) |> Enum.sort() |> Enum.reverse()}
        class="grid grid-cols-2 gap-2"
      >
        <p class="text-right">{year}</p>
        <div class="flex flex-col">
          <.link :for={show <- @other_shows[year]} navigate={~p"/shows/#{show.id}"} class="underline">
            {show.title}
          </.link>
        </div>
      </div>
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

    other_shows =
      Hot.Trakt.Show
      |> Ash.ActionInput.for_action(:recent_shows_by_year, %{})
      |> Ash.run_action!()

    socket =
      socket
      |> stream(:episodes, episodes)
      |> assign(:other_shows, other_shows)
      |> assign(:page_title, "Home")

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
