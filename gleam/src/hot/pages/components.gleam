import gleam/option.{type Option, Some}
import hot/models/card.{type Card}
import lustre/attribute.{class}
import lustre/element.{type Element}
import lustre/element/html

pub fn card_component(card: Card) -> Element(Nil) {
  let title = case card.title {
    "" -> "Untitled"
    t -> t
  }

  html.div([class("p-4 bg-white border rounded-md border-neutral-200")], [
    html.h4([class("mb-2 font-medium")], [html.text(title)]),
    ..description_elements(card.description)
  ])
}

fn description_elements(description: Option(String)) -> List(Element(Nil)) {
  case description {
    Some(desc) if desc != "" -> [
      html.p([class("text-sm break-words")], [html.text(desc)]),
    ]
    _ -> []
  }
}
