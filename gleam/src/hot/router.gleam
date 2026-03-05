import hot/pages/board
import hot/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(request: Request, context: Context) -> Response {
  use <- web.middleware(request, context)

  case wisp.path_segments(request) {
    [] -> wisp.redirect("/board")
    ["board"] -> board.board_page(context.db)
    _ -> wisp.not_found()
  }
}
