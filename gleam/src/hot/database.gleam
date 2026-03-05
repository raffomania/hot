import gleam/bit_array
import gleam/crypto
import gleam/string
import sqlight.{type Connection, type Error}

pub fn connect(path: String) -> Result(Connection, Error) {
  sqlight.open(path)
}

pub fn migrate(conn: Connection) -> Result(Nil, Error) {
  sqlight.exec(
    "
    CREATE TABLE IF NOT EXISTS shows (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      trakt_id INTEGER NOT NULL UNIQUE,
      imdb_id TEXT
    );

    CREATE TABLE IF NOT EXISTS seasons (
      id TEXT PRIMARY KEY,
      show_id TEXT NOT NULL REFERENCES shows(id),
      number INTEGER NOT NULL,
      UNIQUE(show_id, number)
    );

    CREATE TABLE IF NOT EXISTS episodes (
      id TEXT PRIMARY KEY,
      season_id TEXT NOT NULL REFERENCES seasons(id),
      number INTEGER NOT NULL,
      plays INTEGER NOT NULL DEFAULT 0,
      last_watched_at TEXT,
      UNIQUE(season_id, number)
    );

    CREATE TABLE IF NOT EXISTS cards (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL DEFAULT '',
      description TEXT,
      position REAL NOT NULL DEFAULT 0.0,
      list_id INTEGER NOT NULL,
      show_id TEXT REFERENCES shows(id),
      archived_at TEXT,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    PRAGMA foreign_keys = ON;
    ",
    on: conn,
  )
}

pub fn generate_uuid() -> String {
  let bytes = crypto.strong_random_bytes(16)
  let hex = bit_array.base16_encode(bytes) |> string.lowercase
  // Format as UUID v4: 8-4-4-4-12
  let assert Ok(p1) = string.slice(hex, 0, 8) |> Ok
  let assert Ok(p2) = string.slice(hex, 8, 4) |> Ok
  let assert Ok(p3) = string.slice(hex, 12, 4) |> Ok
  let assert Ok(p4) = string.slice(hex, 16, 4) |> Ok
  let assert Ok(p5) = string.slice(hex, 20, 12) |> Ok
  p1 <> "-" <> p2 <> "-" <> p3 <> "-" <> p4 <> "-" <> p5
}

@external(erlang, "database_ffi", "current_timestamp")
pub fn current_timestamp() -> String
