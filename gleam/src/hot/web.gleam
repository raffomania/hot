import wisp.{type Request, type Response}

pub type Context {
  Context(static_directory: String)
}

pub fn middleware(
  request: Request,
  context: Context,
  handler: fn() -> Response,
) -> Response {
  let request = wisp.method_override(request)
  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes
  use request <- wisp.handle_head(request)
  use <- wisp.serve_static(
    request,
    under: "/static",
    from: context.static_directory,
  )

  handler()
}
