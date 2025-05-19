require Logger

defmodule Hot.Trakt.Api do
  def get_watched() do
    api_key = Application.fetch_env!(:hot, :trakt_api_key)
    username = Application.fetch_env!(:hot, :trakt_username)
    url = "https://api.trakt.tv/users/#{username}/watched/shows"

    {:ok, %Finch.Response{body: body, status: 200}} =
      Finch.build(:get, url, [
        {"Content-Type", "application/json"},
        {
          "trakt-api-version",
          "2"
        },
        {
          "trakt-api-key",
          api_key
        },
        {
          "User-Agent",
          "Hotties"
        }
      ])
      |> Finch.request(Hot.Finch)

    {:ok, json} =
      body
      |> JSON.decode()

    json
  end

  def save_shows(shows) do
    shows
    |> Enum.map(fn entry ->
      show =
        Map.get(entry, "show")

      params =
        %{
          title: Map.get(show, "title"),
          trakt_id: get_in(show, ["ids", "trakt"])
        }

      Ash.Changeset.for_create(Hot.Trakt.Show, :create, params)
    end)
    |> Enum.each(&Ash.create!(&1))
  end

  def initial_load() do
    shows_exist =
      Hot.Trakt.Show
      |> Ash.exists?()
      |> IO.inspect()

    if not shows_exist do
      Logger.info("No shows exist yet, performing initial load...")

      get_watched()
      |> save_shows()
    end
  end
end
