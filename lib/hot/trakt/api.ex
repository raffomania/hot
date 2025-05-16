defmodule Hot.Trakt.Api do
  def req() do
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
end
