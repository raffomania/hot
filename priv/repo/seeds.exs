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

# Create sample cards across the two lists
cards_data = [
  # New list (list_id: 1)
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
  %{
    title: "Firefly Reboot",
    description: "Maybe this time it won't get cancelled",
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
  %{
    title: "Breaking Bad",
    description: "Perfect ending to a perfect show",
    list_id: 2
  },
  %{
    title: "The Office",
    description: "That's what she said!",
    list_id: 2
  },
  %{
    title: "Avatar: The Last Airbender",
    description: "Masterpiece of animation",
    list_id: 2
  }
]

# Create active cards
Enum.each(cards_data, fn card_attrs ->
  Ash.create!(Card, card_attrs)
end)

# Create archived cards (shows that were previously tracked but are now archived)
archived_cards_data = [
  %{
    title: "Game of Thrones",
    description: "Great until season 8... we don't talk about season 8",
    # Was in watching before being archived
    list_id: 2
  },
  %{
    title: "Lost",
    description: "Still confused about the ending",
    list_id: 2
  },
  %{
    title: "Sherlock Season 5",
    description: "Never happened, just like the movie",
    # Was in new but never materialized
    list_id: 1
  },
  %{
    title: "Westworld Season 4",
    description: "Got too confusing, archived for mental health",
    list_id: 2
  },
  %{
    title: "True Detective Season 4",
    description: "Rumored but never confirmed",
    list_id: 1
  },
  %{
    title: "Community Movie",
    description: "#SixSeasonsAndAMovie - still waiting for the movie part",
    list_id: 1
  }
]

# Create and immediately archive these cards
archived_cards =
  Enum.map(archived_cards_data, fn card_attrs ->
    card = Ash.create!(Card, card_attrs)
    # Archive the card
    archived_card =
      card
      |> Ash.Changeset.for_update(:archive)
      |> Ash.update!()

    archived_card
  end)

IO.puts("📊 Created #{length(cards_data)} active cards across 2 lists (1: new, 2: watching)")
IO.puts("🗃️  Created #{length(archived_cards)} archived cards for testing archive functionality")
