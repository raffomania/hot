import lustre/attribute.{class, href, rel}
import lustre/element.{type Element}
import lustre/element/html

pub type Page {
  Board
  WatchLog
  Archive
}

pub fn root_layout(
  page_title: String,
  current_page: Page,
  content: List(Element(Nil)),
) -> Element(Nil) {
  html.html([], [
    html.head([], [
      html.meta([attribute.attribute("charset", "utf-8")]),
      html.meta([
        attribute.attribute("name", "viewport"),
        attribute.attribute("content", "width=device-width, initial-scale=1"),
      ]),
      html.title([], page_title <> " · Hot"),
      html.link([rel("stylesheet"), href("/static/css/app.css")]),
    ]),
    html.body([class("bg-white")], [app_layout(current_page, content)]),
  ])
}

fn app_layout(current_page: Page, content: List(Element(Nil))) -> Element(Nil) {
  html.div([], [
    html.nav([class("grid grid-cols-2 p-4 sm:grid-cols-3 sm:px-6 lg:px-8")], [
      html.a([href("/")], [html.h1([class("inline")], [html.text("hotties")])]),
      html.div([class("flex justify-end space-x-4 text-lg sm:justify-center")], [
        nav_link("/shows", "Watch Log", current_page == WatchLog),
        nav_link("/board", "Board", current_page == Board),
        nav_link("/archive", "Archive", current_page == Archive),
      ]),
    ]),
    html.main([], content),
  ])
}

fn nav_link(url: String, label: String, is_active: Bool) -> Element(Nil) {
  let link_class = case is_active {
    True -> "font-bold"
    False -> "underline"
  }
  html.a([href(url), class(link_class)], [html.text(label)])
}
