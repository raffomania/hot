import gleam/list
import hot/models/card.{type Card}
import hot/pages/components
import hot/pages/layout.{Board, root_layout}
import lustre/attribute.{class}
import lustre/element
import lustre/element/html
import sqlight.{type Connection}
import wisp.{type Response}

pub fn board_page(db: Connection) -> Response {
  let cards = case card.list_active(db) {
    Ok(cards) -> cards
    Error(_) -> []
  }

  let new_cards = list.filter(cards, fn(c) { c.list_id == 1 })
  let watching_cards = list.filter(cards, fn(c) { c.list_id == 2 })

  let page =
    root_layout("Board", Board, [
      html.div([class("flex flex-wrap justify-center gap-4 px-4 py-8")], [
        list_column("new", new_cards),
        list_column("watching", watching_cards),
      ]),
    ])

  wisp.ok()
  |> wisp.html_body(element.to_document_string(page))
}

fn list_column(title: String, cards: List(Card)) -> element.Element(Nil) {
  html.div(
    [class("flex flex-col p-4 pb-10 rounded-md bg-neutral-100 w-72 max-w-96")],
    [
      html.div([class("flex items-center justify-between mb-4")], [
        html.h3([class("px-1 font-semibold")], [html.text(title)]),
      ]),
      html.div(
        [class("flex-1 space-y-2")],
        list.map(cards, fn(c) { components.card_component(c) }),
      ),
    ],
  )
}
