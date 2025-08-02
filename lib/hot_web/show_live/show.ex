defmodule HotWeb.ShowLive.Show do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl px-4 mx-auto my-8">
      <h1 class="my-8 text-lg font-bold text-center">{@show.title}</h1>
      <div class="grid grid-cols-2 gap-y-4 gap-x-2 sm:grid-cols-4">
        <h2 class="inline mr-4 font-bold sm:text-right">Links</h2>
        <p>
          <a href={"https://trakt.tv/search/trakt/#{@show.trakt_id}?id_type=show"} class="underline">
            Trakt
          </a>
          •
          <a href={"https://imdb.com/title/#{@show.imdb_id}"} class="underline">
            IMDB
          </a>
        </p>
        <h2 class="inline mr-4 font-bold sm:text-right">Total episodes watched</h2>
        <p>
          {@seasons}
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    show = Hot.Trakt.Show |> Ash.get!(id)

    seasons =
      Hot.Trakt.Show
      |> Ash.ActionInput.for_action(:count_episodes, %{id: id})
      |> Ash.run_action!()

    {:noreply,
     socket
     |> assign(:page_title, show.title)
     |> assign(:show, show)
     |> assign(:seasons, seasons)
     |> assign(:current_page, :shows)}
  end
end
