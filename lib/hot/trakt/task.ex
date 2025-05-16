defmodule Hot.Trakt.Task do
  def update(shows) do
    shows
    |> Enum.map(fn entry ->
      show =
        Map.get(entry, "show")
        |> IO.inspect()

      params = %{
        title: Map.get(show, "title"),
        trakt_id: Map.get(show, "ids") |> Map.get("trakt")
      }

      Ash.Changeset.for_create(Hot.Trakt.Show, :create, params)
    end)
    |> Enum.each(&Ash.create!(&1))
  end
end
