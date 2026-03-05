import gleam/http
import hot/pages/board
import hot/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(request: Request, context: Context) -> Response {
  use <- web.middleware(request, context)

  case wisp.path_segments(request), request.method {
    [], _ -> wisp.redirect("/board")
    ["board"], _ -> board.board_page(context.db, request)
    ["board", "cards"], http.Post -> board.create_card(context.db, request)
    ["board", "cards", id], http.Patch ->
      board.update_card(context.db, request, id)
    ["board", "cards", id, "edit"], http.Get ->
      board.edit_card_form(context.db, request, id)
    ["board", "cards", id, "finish"], http.Post ->
      board.finish_card(context.db, id)
    ["board", "cards", id, "cancel"], http.Post ->
      board.cancel_card(context.db, id)
    _, _ -> wisp.not_found()
  }
}
