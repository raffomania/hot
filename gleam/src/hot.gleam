import gleam/erlang/process
import gleam/int
import gleam/io
import hot/config
import hot/database
import hot/router
import hot/web
import mist
import radiate
import wisp
import wisp/wisp_mist

const port = 4001

const db_path = "hot_gleam_dev.db"

pub fn main() {
  wisp.configure_logger()

  require_env("SHARED_PASSWORD", config.shared_password())
  let secret_key_base = require_env("SECRET_KEY_BASE", config.secret_key_base())

  let assert Ok(db) = database.connect(db_path)
  let assert Ok(_) = database.migrate(db)

  let context = web.Context(static_directory: static_directory(), db: db)
  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    handler
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(port)
    |> mist.start

  let _ =
    radiate.new()
    |> radiate.add_dir("src")
    |> radiate.start()

  io.println("Hot (Gleam) running on http://localhost:" <> int.to_string(port))
  process.sleep_forever()
}

fn static_directory() -> String {
  let assert Ok(priv) = wisp.priv_directory("hot")
  priv <> "/static"
}

fn require_env(name: String, value: Result(String, Nil)) -> String {
  case value {
    Ok(v) -> v
    Error(_) -> {
      io.println_error(
        "Error: " <> name <> " environment variable is not set. Exiting.",
      )
      halt(1)
    }
  }
}

@external(erlang, "erlang", "halt")
fn halt(status: Int) -> a
