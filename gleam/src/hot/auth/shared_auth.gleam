import gleam/bit_array
import gleam/crypto
import hot/config
import wisp.{type Request, type Response}

const cookie_name = "hot_auth"

const cookie_value = "authenticated"

/// Max age: 30 days in seconds
const cookie_max_age = 2_592_000

/// Validate a password against the SHARED_PASSWORD env var using
/// constant-time comparison to prevent timing attacks.
pub fn validate_password(password: String) -> Bool {
  case config.shared_password() {
    Ok(expected) ->
      crypto.secure_compare(
        bit_array.from_string(password),
        bit_array.from_string(expected),
      )
    Error(_) -> False
  }
}

/// Check if a request has a valid auth cookie.
pub fn is_authenticated(request: Request) -> Bool {
  case wisp.get_cookie(request, cookie_name, wisp.Signed) {
    Ok(value) if value == cookie_value -> True
    _ -> False
  }
}

/// Set the auth cookie on a response.
pub fn set_auth_cookie(response: Response, request: Request) -> Response {
  wisp.set_cookie(
    response,
    request,
    cookie_name,
    cookie_value,
    wisp.Signed,
    cookie_max_age,
  )
}

/// Remove the auth cookie by setting max_age to 0.
pub fn clear_auth_cookie(response: Response, request: Request) -> Response {
  wisp.set_cookie(response, request, cookie_name, "", wisp.Signed, 0)
}

/// Middleware that requires authentication. Redirects to login if not
/// authenticated, preserving the original path as a query parameter.
pub fn require_auth(request: Request, handler: fn() -> Response) -> Response {
  case is_authenticated(request) {
    True -> handler()
    False -> {
      let return_to = request.path
      wisp.redirect("/auth/login?return_to=" <> return_to)
    }
  }
}
