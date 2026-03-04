import gleam/erlang/process
import gleam/int
import gleam/io
import hot/router
import hot/web
import mist
import wisp
import wisp/wisp_mist

const port = 4001

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let context = web.Context(static_directory: static_directory())
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
