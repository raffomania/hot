import gleam/erlang/process
import gleam/int
import gleam/io
import hot/config
import hot/database
import hot/router
import hot/web
import mist
import wisp
import wisp/wisp_mist

const port = 4001

const db_path = "hot_gleam_dev.db"

pub fn main() {
  wisp.configure_logger()

  case config.shared_password() {
    Error(_) -> {
      io.println_error(
        "Error: SHARED_PASSWORD environment variable is not set. Exiting.",
      )
      halt(1)
    }
    Ok(_) -> Nil
  }

  let secret_key_base = wisp.random_string(64)

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

  io.println("Hot (Gleam) running on http://localhost:" <> int.to_string(port))
  process.sleep_forever()
}

fn static_directory() -> String {
  let assert Ok(priv) = wisp.priv_directory("hot")
  priv <> "/static"
}

@external(erlang, "erlang", "halt")
fn halt(status: Int) -> Nil
