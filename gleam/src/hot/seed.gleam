import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import hot/database
import hot/models/card

const db_path = "hot_gleam_dev.db"

pub fn main() {
  let assert Ok(db) = database.connect(db_path)
  let assert Ok(Nil) = database.migrate(db)

  let active_cards = [
    // New list (list_id: 1)
    #("House of the Dragon Season 3", Some("Upcoming season looks epic!"), 1),
    #("The Last of Us Part II", Some("Check out the new trailer"), 1),
    #("Dune: Part Three", Some("Paul's journey continues"), 1),
    #(
      "Firefly Reboot",
      Some("Maybe this time it won't get cancelled"),
      1,
    ),
    // Watching list (list_id: 2)
    #("Stranger Things", Some("Season 4 finale was incredible"), 2),
    #("The Mandalorian", Some("Baby Yoda is the best"), 2),
    #("Wednesday", Some("Addams family spinoff"), 2),
    #("Breaking Bad", Some("Perfect ending to a perfect show"), 2),
    #("The Office", Some("That's what she said!"), 2),
    #(
      "Avatar: The Last Airbender",
      Some("Masterpiece of animation"),
      2,
    ),
  ]

  let archived_cards = [
    #(
      "Game of Thrones",
      Some("Great until season 8... we don't talk about season 8"),
      "finished",
    ),
    #("Lost", Some("Still confused about the ending"), "finished"),
    #(
      "Sherlock Season 5",
      Some("Never happened, just like the movie"),
      "cancelled",
    ),
    #(
      "Westworld Season 4",
      Some("Got too confusing, archived for mental health"),
      "cancelled",
    ),
  ]

  // Create active cards
  list.each(active_cards, fn(entry) {
    let #(title, description, list_id) = entry
    let assert Ok(_) = card.create(db, title, description, list_id)
    Nil
  })

  // Create archived cards
  list.each(archived_cards, fn(entry) {
    let #(title, description, archive_type) = entry
    let assert Ok(c) = card.create(db, title, description, 1)
    case archive_type {
      "finished" -> {
        let assert Ok(_) = card.mark_finished(db, c.id)
        Nil
      }
      _ -> {
        let assert Ok(_) = card.mark_cancelled(db, c.id)
        Nil
      }
    }
  })

  io.println(
    "Created "
    <> int.to_string(list.length(active_cards))
    <> " active cards and "
    <> int.to_string(list.length(archived_cards))
    <> " archived cards",
  )
}
