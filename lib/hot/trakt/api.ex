require Logger

defmodule Hot.Trakt.Api do
  def get_watched() do
    username = Application.fetch_env!(:hot, :trakt_username)
    path = "/users/#{username}/watched/shows"

    {:ok, %Finch.Response{body: body, status: 200}} =
      req(path)

    {:ok, json} =
      body
      |> JSON.decode()

    json
  end

  def req(path) do
    api_key = Application.fetch_env!(:hot, :trakt_api_key)

    Finch.build(:get, "https://api.trakt.tv" <> path, [
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
  end

  def save_shows(shows) do
    shows
    |> Enum.map(&create_show_changeset/1)
    |> Enum.each(&Ash.create!(&1))
  end

  def create_show_changeset(entry) do
    params =
      %{
        title: get_in(entry, ["show", "title"]),
        trakt_id: get_in(entry, ["show", "ids", "trakt"]),
        imdb_id: get_in(entry, ["show", "ids", "imdb"]),
        seasons: Map.get(entry, "seasons", [])
      }

    Ash.Changeset.for_create(Hot.Trakt.Show, :create, params)
  end

  def update_db() do
    get_watched()
    |> save_shows()
  end
end
