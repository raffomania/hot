# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Hot.Repo.insert!(%Hot.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Hot.Trakt.{Card}

# Create sample cards across different lists
cards_data = [
  # Trailers list (list_id: 1)
  %{
    title: "House of the Dragon Season 3",
    description: "Upcoming season looks epic!",
    list_id: 1
  },
  %{
    title: "The Last of Us Part II",
    description: "Check out the new trailer",
    list_id: 1
  },
  %{
    title: "Dune: Part Three",
    description: "Paul's journey continues",
    list_id: 1
  },

  # Watching list (list_id: 2)
  %{
    title: "Stranger Things",
    description: "Season 4 finale was incredible",
    list_id: 2
  },
  %{
    title: "The Mandalorian",
    description: "Baby Yoda is the best",
    list_id: 2
  },
  %{
    title: "Wednesday",
    description: "Addams family spinoff",
    list_id: 2
  },

  # Cancelled list (list_id: 3)
  %{
    title: "Game of Thrones",
    description: "Disappointing final season",
    list_id: 3
  },
  %{title: "Firefly", description: "Cancelled too soon", list_id: 3},

  # Finished list (list_id: 4)
  %{
    title: "Breaking Bad",
    description: "Perfect ending to a perfect show",
    list_id: 4
  },
  %{
    title: "The Office",
    description: "That's what she said!",
    list_id: 4
  },
  %{
    title: "Avatar: The Last Airbender",
    description: "Masterpiece of animation",
    list_id: 4
  },
  %{
    title: "Chernobyl",
    description: "Haunting and brilliant",
    list_id: 4
  },
  %{
    title: "Better Call Saul",
    description: "Saul's origin story",
    list_id: 4
  },
  %{
    title: "The Wire",
    description: "Baltimore crime drama",
    list_id: 4
  },
  %{
    title: "Westworld",
    description: "Complex AI narrative",
    list_id: 4
  },
  %{
    title: "True Detective",
    description: "Season 1 was phenomenal",
    list_id: 4
  },
  %{
    title: "Mad Men",
    description: "60s advertising drama",
    list_id: 4
  },
  %{
    title: "The Sopranos",
    description: "Classic mob series",
    list_id: 4
  },
  %{
    title: "Lost",
    description: "Island mystery show",
    list_id: 4
  },
  %{
    title: "Friends",
    description: "Classic sitcom",
    list_id: 4
  }
]

# Create cards
Enum.each(cards_data, fn card_attrs ->
  Ash.create!(Card, card_attrs)
end)

IO.puts(
  "📊 Created #{length(cards_data)} cards across 4 lists (1: Trailers, 2: Watching, 3: Cancelled, 4: Finished)"
)
