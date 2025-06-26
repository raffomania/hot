defmodule HotWeb.ShowLive.Index do
  use HotWeb, :live_view
  require Ash.Expr

  @impl true
  def render(assigns) do
    IO.inspect(DateTime.utc_now())

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
    <div class="grid max-w-4xl grid-cols-1 gap-8 mx-auto mt-16 sm:grid-cols-2 md:grid-cols-3">
      <div
        :for={year <- Map.keys(@other_shows) |> Enum.sort() |> Enum.reverse()}
        class="grid grid-cols-[3rem_1fr] gap-4"
      >
        <p class="font-bold text-right">{year}</p>
        <div class="flex flex-col">
          <.link :for={show <- @other_shows[year]} navigate={~p"/shows/#{show.id}"} class="underline">
            {show.title}
          </.link>
        </div>
      </div>
    </div>
    <div :if={@authenticated} class="pt-12 mt-12 text-center border-t border-neutral-300">
      <.form for={%{}} action={~p"/auth/logout"} method="delete">
        <.button type="submit">
          logout
        </.button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
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

    authenticated = Map.get(session, "authenticated") == true

    socket =
      socket
      |> stream(:episodes, episodes)
      |> assign(:other_shows, other_shows)
      |> assign(:page_title, "Home")
      |> assign(:current_page, :shows)
      |> assign(:authenticated, authenticated)

    {:ok, socket}
  end

  def format_date_relative(now \\ DateTime.utc_now(), later) do
    now_date = DateTime.to_date() |> DateTime.f()
    later_date = DateTime.to_date(later)
    days_diff = DateTime.diff(now_date, later_date, :day)

    IO.inspect(later)

    cond do
      days_diff < 0 -> "in the future???"
      days_diff == 0 -> "today"
      days_diff == 1 -> "1 day ago"
      days_diff <= 7 -> "#{days_diff} days ago"
      days_diff <= 11 -> "1 week ago"
      true -> "#{round(days_diff / 7)} weeks ago"
    end
  end

  def format_date_absolute(date) do
    Calendar.strftime(date, "%d.%m.%y")
  end

  def format_season_episode_number(n) do
    n |> to_string() |> String.pad_leading(2, "0")
  end
end
