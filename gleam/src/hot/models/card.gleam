import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import gleam/result
import hot/database
import hot/models/position
import sqlight.{type Connection, type Error}

pub type Card {
  Card(
    id: String,
    title: String,
    description: Option(String),
    position: Float,
    list_id: Int,
    show_id: Option(String),
    archived_at: Option(String),
    inserted_at: String,
    updated_at: String,
  )
}

fn card_decoder() -> decode.Decoder(Card) {
  use id <- decode.field(0, decode.string)
  use title <- decode.field(1, decode.string)
  use description <- decode.field(2, decode.optional(decode.string))
  use position <- decode.field(3, decode.float)
  use list_id <- decode.field(4, decode.int)
  use show_id <- decode.field(5, decode.optional(decode.string))
  use archived_at <- decode.field(6, decode.optional(decode.string))
  use inserted_at <- decode.field(7, decode.string)
  use updated_at <- decode.field(8, decode.string)
  decode.success(Card(
    id:,
    title:,
    description:,
    position:,
    list_id:,
    show_id:,
    archived_at:,
    inserted_at:,
    updated_at:,
  ))
}

pub fn create(
  conn: Connection,
  title: String,
  description: Option(String),
  list_id: Int,
) -> Result(Card, Error) {
  let id = database.generate_uuid()
  let now = database.current_timestamp()
  use pos <- result.try(position.assign_end_position(conn, list_id))
  sqlight.query(
    "INSERT INTO cards (id, title, description, position, list_id, inserted_at, updated_at)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
     RETURNING *",
    on: conn,
    with: [
      sqlight.text(id),
      sqlight.text(title),
      sqlight.nullable(sqlight.text, description),
      sqlight.float(pos),
      sqlight.int(list_id),
      sqlight.text(now),
      sqlight.text(now),
    ],
    expecting: card_decoder(),
  )
  |> result.map(fn(rows) {
    let assert [card] = rows
    card
  })
}

pub fn get(conn: Connection, id: String) -> Result(Option(Card), Error) {
  sqlight.query(
    "SELECT * FROM cards WHERE id = ?1",
    on: conn,
    with: [sqlight.text(id)],
    expecting: card_decoder(),
  )
  |> result.map(fn(rows) {
    case rows {
      [card] -> Some(card)
      _ -> None
    }
  })
}

pub fn list_active(conn: Connection) -> Result(List(Card), Error) {
  sqlight.query(
    "SELECT * FROM cards WHERE list_id IN (1, 2) ORDER BY list_id, position",
    on: conn,
    with: [],
    expecting: card_decoder(),
  )
}

pub fn list_by_list(conn: Connection, list_id: Int) -> Result(List(Card), Error) {
  sqlight.query(
    "SELECT * FROM cards WHERE list_id = ?1 ORDER BY position",
    on: conn,
    with: [sqlight.int(list_id)],
    expecting: card_decoder(),
  )
}

pub fn list_finished(conn: Connection) -> Result(List(Card), Error) {
  sqlight.query(
    "SELECT * FROM cards WHERE list_id = 3 ORDER BY position",
    on: conn,
    with: [],
    expecting: card_decoder(),
  )
}

pub fn list_cancelled(conn: Connection) -> Result(List(Card), Error) {
  sqlight.query(
    "SELECT * FROM cards WHERE list_id = 4 ORDER BY position",
    on: conn,
    with: [],
    expecting: card_decoder(),
  )
}

pub fn update(
  conn: Connection,
  id: String,
  title: String,
  description: Option(String),
) -> Result(Option(Card), Error) {
  let now = database.current_timestamp()
  sqlight.query(
    "UPDATE cards SET title = ?1, description = ?2, updated_at = ?3
     WHERE id = ?4
     RETURNING *",
    on: conn,
    with: [
      sqlight.text(title),
      sqlight.nullable(sqlight.text, description),
      sqlight.text(now),
      sqlight.text(id),
    ],
    expecting: card_decoder(),
  )
  |> result.map(fn(rows) {
    case rows {
      [card] -> Some(card)
      _ -> None
    }
  })
}

pub fn delete(conn: Connection, id: String) -> Result(Bool, Error) {
  sqlight.query(
    "DELETE FROM cards WHERE id = ?1 RETURNING id",
    on: conn,
    with: [sqlight.text(id)],
    expecting: decode.field(0, decode.string, fn(s) { decode.success(s) }),
  )
  |> result.map(fn(rows) {
    case rows {
      [_] -> True
      _ -> False
    }
  })
}

pub fn mark_finished(conn: Connection, id: String) -> Result(Option(Card), Error) {
  let now = database.current_timestamp()
  sqlight.query(
    "UPDATE cards SET list_id = 3, archived_at = ?1, updated_at = ?1
     WHERE id = ?2
     RETURNING *",
    on: conn,
    with: [sqlight.text(now), sqlight.text(id)],
    expecting: card_decoder(),
  )
  |> result.map(fn(rows) {
    case rows {
      [card] -> Some(card)
      _ -> None
    }
  })
}

pub fn mark_cancelled(
  conn: Connection,
  id: String,
) -> Result(Option(Card), Error) {
  let now = database.current_timestamp()
  sqlight.query(
    "UPDATE cards SET list_id = 4, archived_at = ?1, updated_at = ?1
     WHERE id = ?2
     RETURNING *",
    on: conn,
    with: [sqlight.text(now), sqlight.text(id)],
    expecting: card_decoder(),
  )
  |> result.map(fn(rows) {
    case rows {
      [card] -> Some(card)
      _ -> None
    }
  })
}

pub fn unarchive(conn: Connection, id: String) -> Result(Option(Card), Error) {
  let now = database.current_timestamp()
  use pos <- result.try(position.assign_end_position(conn, 1))
  sqlight.query(
    "UPDATE cards SET list_id = 1, archived_at = NULL, position = ?1, updated_at = ?2
     WHERE id = ?3
     RETURNING *",
    on: conn,
    with: [sqlight.float(pos), sqlight.text(now), sqlight.text(id)],
    expecting: card_decoder(),
  )
  |> result.map(fn(rows) {
    case rows {
      [card] -> Some(card)
      _ -> None
    }
  })
}

pub fn move_to_position(
  conn: Connection,
  id: String,
  new_list_id: Int,
  target_index: Int,
) -> Result(Option(Card), Error) {
  let now = database.current_timestamp()
  use pos <- result.try(position.calculate_move_position(
    conn,
    new_list_id,
    target_index,
    id,
  ))
  sqlight.query(
    "UPDATE cards SET list_id = ?1, position = ?2, updated_at = ?3
     WHERE id = ?4
     RETURNING *",
    on: conn,
    with: [
      sqlight.int(new_list_id),
      sqlight.float(pos),
      sqlight.text(now),
      sqlight.text(id),
    ],
    expecting: card_decoder(),
  )
  |> result.map(fn(rows) {
    case rows {
      [card] -> Some(card)
      _ -> None
    }
  })
}
