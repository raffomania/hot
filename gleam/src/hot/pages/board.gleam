import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import hot/models/card.{type Card}
import hot/pages/components
import hot/pages/layout.{Board, root_layout}
import lustre/attribute.{class, id}
import lustre/element
import lustre/element/html
import sqlight.{type Connection}
import wisp.{type Request, type Response}

pub fn board_page(db: Connection, request: Request) -> Response {
  let cards = case card.list_active(db) {
    Ok(cards) -> cards
    Error(_) -> []
  }

  let new_cards = list.filter(cards, fn(c) { c.list_id == 1 })
  let watching_cards = list.filter(cards, fn(c) { c.list_id == 2 })

  let board_content =
    html.div([class("flex flex-wrap justify-center gap-4 px-4 py-8")], [
      list_column("new", 1, new_cards),
      list_column("watching", 2, watching_cards),
    ])

  // If HTMX request, return just the board content fragment
  let is_htmx =
    list.any(request.headers, fn(h) { h.0 == "hx-request" && h.1 == "true" })

  case is_htmx {
    True ->
      wisp.ok()
      |> wisp.html_body(element.to_string(board_content))
    False -> {
      let page = root_layout("Board", Board, [board_content])
      wisp.ok()
      |> wisp.html_body(element.to_document_string(page))
    }
  }
}

pub fn create_card(db: Connection, request: Request) -> Response {
  use formdata <- wisp.require_form(request)

  let list_id =
    list.find(formdata.values, fn(v) { v.0 == "list_id" })
    |> result.try(fn(v) { int.parse(v.1) })
    |> result.unwrap(1)

  case card.create(db, "", None, list_id) {
    Ok(new_card) -> {
      let html = components.card_edit_component(new_card, "title")
      wisp.ok()
      |> wisp.html_body(element.to_string(html))
    }
    Error(_) -> wisp.internal_server_error()
  }
}

pub fn update_card(db: Connection, request: Request, id: String) -> Response {
  use formdata <- wisp.require_form(request)

  let title =
    list.find(formdata.values, fn(v) { v.0 == "title" })
    |> result.map(fn(v) { v.1 })
    |> result.unwrap("")

  let description =
    list.find(formdata.values, fn(v) { v.0 == "description" })
    |> result.map(fn(v) { v.1 })

  let desc_option = case description {
    Ok(d) if d != "" -> Some(d)
    _ -> None
  }

  case card.update(db, id, title, desc_option) {
    Ok(Some(updated_card)) -> {
      let html = components.card_component(updated_card)
      wisp.ok()
      |> wisp.html_body(element.to_string(html))
    }
    _ -> wisp.not_found()
  }
}

pub fn edit_card_form(db: Connection, request: Request, id: String) -> Response {
  let field =
    wisp.get_query(request)
    |> list.find(fn(v) { v.0 == "field" })
    |> result.map(fn(v) { v.1 })
    |> result.unwrap("title")

  case card.get(db, id) {
    Ok(Some(c)) -> {
      let html = case field {
        "none" -> components.card_component(c)
        f -> components.card_edit_component(c, f)
      }
      wisp.ok()
      |> wisp.html_body(element.to_string(html))
    }
    _ -> wisp.not_found()
  }
}

pub fn finish_card(db: Connection, id: String) -> Response {
  case card.mark_finished(db, id) {
    Ok(Some(_)) -> wisp.ok()
    _ -> wisp.not_found()
  }
}

pub fn cancel_card(db: Connection, id: String) -> Response {
  case card.mark_cancelled(db, id) {
    Ok(Some(_)) -> wisp.ok()
    _ -> wisp.not_found()
  }
}

fn list_column(
  title: String,
  list_id: Int,
  cards: List(Card),
) -> element.Element(Nil) {
  html.div(
    [class("flex flex-col p-4 pb-10 rounded-md bg-neutral-100 w-72 max-w-96")],
    [
      html.div([class("flex items-center justify-between mb-4")], [
        html.h3([class("px-1 font-semibold")], [html.text(title)]),
        components.add_card_button(list_id),
      ]),
      html.div(
        [
          id("list-" <> int.to_string(list_id) <> "-cards"),
          class("flex-1 space-y-2"),
        ],
        list.map(cards, fn(c) { components.card_component(c) }),
      ),
    ],
  )
}
