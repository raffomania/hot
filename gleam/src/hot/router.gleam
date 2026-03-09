import gleam/http
import hot/auth/shared_auth
import hot/pages/auth_page
import hot/pages/board
import hot/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(request: Request, context: Context) -> Response {
  use <- web.middleware(request, context)

  case wisp.path_segments(request), request.method {
    // Public routes
    [], _ -> wisp.redirect("/board")
    ["auth", "login"], http.Get -> auth_page.login_page(request)
    ["auth", "login"], http.Post -> auth_page.authenticate(request)
    ["auth", "logout"], http.Post -> auth_page.logout(request)

    // Everything else requires authentication
    _, _ -> {
      use <- shared_auth.require_auth(request)
      protected_routes(request, context)
    }
  }
}

fn protected_routes(request: Request, context: Context) -> Response {
  case wisp.path_segments(request), request.method {
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
    ["board", "cards", id, "move"], http.Post ->
      board.move_card(context.db, request, id)
    _, _ -> wisp.not_found()
  }
}
