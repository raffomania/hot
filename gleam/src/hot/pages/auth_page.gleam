import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import hot/auth/shared_auth
import lustre/attribute.{class, href, type_}
import lustre/element
import lustre/element/html
import wisp.{type Request, type Response}

pub fn login_page(request: Request) -> Response {
  // If already authenticated, redirect to board
  case shared_auth.is_authenticated(request) {
    True -> wisp.redirect("/board")
    False -> {
      let return_to = get_return_to(request)
      render_login(return_to, None)
    }
  }
}

pub fn authenticate(request: Request) -> Response {
  use formdata <- wisp.require_form(request)

  let password =
    list.find(formdata.values, fn(v) { v.0 == "password" })
    |> result.map(fn(v) { v.1 })
    |> result.unwrap("")

  let return_to =
    list.find(formdata.values, fn(v) { v.0 == "return_to" })
    |> result.map(fn(v) { v.1 })
    |> result.unwrap("/board")

  case shared_auth.validate_password(password) {
    True -> {
      let redirect_to = case return_to {
        "" -> "/board"
        path -> path
      }
      wisp.redirect(redirect_to)
      |> shared_auth.set_auth_cookie(request)
    }
    False -> render_login(return_to, Some("Invalid password. Who are you?"))
  }
}

pub fn logout(request: Request) -> Response {
  wisp.redirect("/")
  |> shared_auth.clear_auth_cookie(request)
}

fn get_return_to(request: Request) -> String {
  wisp.get_query(request)
  |> list.find(fn(v) { v.0 == "return_to" })
  |> result.map(fn(v) { v.1 })
  |> result.unwrap("")
}

fn render_login(return_to: String, error: Option(String)) -> Response {
  let error_html = case error {
    Some(msg) -> html.p([class("mb-4 text-sm text-red-600")], [html.text(msg)])
    None -> html.text("")
  }

  let page =
    html.html([], [
      html.head([], [
        html.meta([attribute.attribute("charset", "utf-8")]),
        html.meta([
          attribute.attribute("name", "viewport"),
          attribute.attribute("content", "width=device-width, initial-scale=1"),
        ]),
        html.title([], "Login · Hot"),
        html.link([
          attribute.attribute("rel", "stylesheet"),
          href("/static/css/app.css"),
        ]),
      ]),
      html.body(
        [class("flex items-center justify-center min-h-screen bg-white")],
        [
          html.div([class("w-full max-w-md p-8")], [
            html.div([class("mb-8 text-center")], [
              html.p([class("text-2xl")], [html.text("(｡◕‿‿◕｡)")]),
            ]),
            error_html,
            html.form(
              [
                attribute.method("post"),
                attribute.action("/auth/login"),
                class("space-y-4"),
              ],
              [
                html.input([
                  type_("hidden"),
                  attribute.name("return_to"),
                  attribute.value(return_to),
                ]),
                html.input([
                  type_("password"),
                  attribute.name("password"),
                  attribute.attribute("required", ""),
                  attribute.attribute("autofocus", ""),
                  attribute.attribute("placeholder", "Password"),
                  class(
                    "w-full px-3 py-2 border border-neutral-300 rounded-md focus:outline-none focus:ring-1 focus:ring-neutral-400",
                  ),
                ]),
                html.button(
                  [
                    type_("submit"),
                    class(
                      "w-full px-4 py-2 text-white bg-neutral-800 rounded-md hover:bg-neutral-700",
                    ),
                  ],
                  [html.text("Enter")],
                ),
              ],
            ),
          ]),
        ],
      ),
    ])

  wisp.ok()
  |> wisp.html_body(element.to_document_string(page))
}
