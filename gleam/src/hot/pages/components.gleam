import gleam/int
import gleam/list as glist
import gleam/option.{type Option, Some}
import hot/models/card.{type Card}
import lustre/attribute.{attribute, class, id, name, type_, value}
import lustre/element.{type Element}
import lustre/element/html

pub fn card_component(card: Card) -> Element(Nil) {
  let title = case card.title {
    "" -> "Untitled"
    t -> t
  }
  let card_id = "card-" <> card.id

  html.div(
    [
      id(card_id),
      class("p-4 bg-white border rounded-md border-neutral-200"),
      attribute("data-card-id", card.id),
      attribute("tabindex", "0"),
      attribute("role", "button"),
      attribute("aria-label", title),
    ],
    glist.flatten([
      [
        html.h4(
          [
            class("mb-2 font-medium cursor-pointer hover:text-blue-600"),
            attribute(
              "hx-get",
              "/board/cards/" <> card.id <> "/edit?field=title",
            ),
            attribute("hx-target", "#" <> card_id),
            attribute("hx-swap", "outerHTML"),
          ],
          [html.text(title)],
        ),
      ],
      description_display(card),
      [action_buttons(card)],
    ]),
  )
}

pub fn card_edit_component(card: Card, field: String) -> Element(Nil) {
  let title = case card.title {
    "" -> "Untitled"
    t -> t
  }
  let card_id = "card-" <> card.id

  html.div(
    [
      id(card_id),
      class("p-4 bg-white border rounded-md border-blue-300"),
      attribute("data-card-id", card.id),
      attribute("tabindex", "0"),
      attribute("role", "button"),
      attribute("aria-label", title),
    ],
    glist.flatten([
      case field {
        "title" -> [
          html.form(
            [
              attribute("hx-patch", "/board/cards/" <> card.id),
              attribute("hx-target", "#" <> card_id),
              attribute("hx-swap", "outerHTML"),
            ],
            [
              html.input([
                type_("text"),
                name("title"),
                value(card.title),
                class(
                  "w-full px-2 py-1 mb-2 font-medium border rounded border-neutral-300",
                ),
              ]),
              hidden_description(card.description),
            ],
          ),
        ]
        "description" -> [
          html.h4([class("mb-2 font-medium")], [html.text(title)]),
          html.form(
            [
              attribute("hx-patch", "/board/cards/" <> card.id),
              attribute("hx-target", "#" <> card_id),
              attribute("hx-swap", "outerHTML"),
            ],
            [
              html.input([type_("hidden"), name("title"), value(card.title)]),
              html.textarea(
                [
                  name("description"),
                  class(
                    "w-full px-2 py-1 text-sm border rounded border-neutral-300",
                  ),
                  attribute("rows", "3"),
                ],
                option.unwrap(card.description, ""),
              ),
            ],
          ),
        ]
        _ -> [html.h4([class("mb-2 font-medium")], [html.text(title)])]
      },
      case field {
        "title" -> description_elements(card.description)
        _ -> description_display(card)
      },
      [action_buttons(card)],
    ]),
  )
}

pub fn add_card_button(list_id: Int) -> Element(Nil) {
  html.button(
    [
      class("px-2 py-1 text-sm text-neutral-500 hover:text-neutral-700"),
      attribute("hx-post", "/board/cards"),
      attribute("hx-vals", "{\"list_id\": " <> int.to_string(list_id) <> "}"),
      attribute("hx-target", "#list-" <> int.to_string(list_id) <> "-cards"),
      attribute("hx-swap", "beforeend"),
    ],
    [html.text("+ Add Card")],
  )
}

fn description_display(card: Card) -> List(Element(Nil)) {
  let card_id = "card-" <> card.id
  case card.description {
    Some(desc) if desc != "" -> [
      html.p(
        [
          class("text-sm break-words cursor-pointer hover:text-blue-600"),
          attribute(
            "hx-get",
            "/board/cards/" <> card.id <> "/edit?field=description",
          ),
          attribute("hx-target", "#" <> card_id),
          attribute("hx-swap", "outerHTML"),
        ],
        [html.text(desc)],
      ),
    ]
    _ -> [
      html.p(
        [
          class(
            "text-sm italic cursor-pointer text-neutral-400 hover:text-blue-600",
          ),
          attribute(
            "hx-get",
            "/board/cards/" <> card.id <> "/edit?field=description",
          ),
          attribute("hx-target", "#" <> card_id),
          attribute("hx-swap", "outerHTML"),
        ],
        [html.text("Add description...")],
      ),
    ]
  }
}

fn description_elements(description: Option(String)) -> List(Element(Nil)) {
  case description {
    Some(desc) if desc != "" -> [
      html.p([class("text-sm break-words")], [html.text(desc)]),
    ]
    _ -> []
  }
}

fn hidden_description(description: Option(String)) -> Element(Nil) {
  html.input([
    type_("hidden"),
    name("description"),
    value(option.unwrap(description, "")),
  ])
}

fn action_buttons(card: Card) -> Element(Nil) {
  let card_id = "card-" <> card.id
  html.div([class("flex gap-2 mt-2")], [
    html.button(
      [
        class(
          "px-2 py-1 text-xs text-green-700 rounded bg-green-50 hover:bg-green-100",
        ),
        attribute("hx-post", "/board/cards/" <> card.id <> "/finish"),
        attribute("hx-target", "#" <> card_id),
        attribute("hx-swap", "delete"),
      ],
      [html.text("Finish")],
    ),
    html.button(
      [
        class(
          "px-2 py-1 text-xs text-red-700 rounded bg-red-50 hover:bg-red-100",
        ),
        attribute("hx-post", "/board/cards/" <> card.id <> "/cancel"),
        attribute("hx-target", "#" <> card_id),
        attribute("hx-swap", "delete"),
      ],
      [html.text("Cancel")],
    ),
  ])
}
