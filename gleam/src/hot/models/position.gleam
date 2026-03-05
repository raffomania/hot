import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import sqlight.{type Connection, type Error}

pub const gap = 10.0

pub const min_gap = 0.002

pub fn assign_end_position(
  conn: Connection,
  list_id: Int,
) -> Result(Float, Error) {
  use positions <- result.try(get_sorted_positions(conn, list_id, None))
  case list.last(positions) {
    Ok(#(_, last_pos)) -> Ok(last_pos +. gap)
    Error(_) -> Ok(gap)
  }
}

pub fn calculate_move_position(
  conn: Connection,
  list_id: Int,
  target_index: Int,
  exclude_card_id: String,
) -> Result(Float, Error) {
  use positions <- result.try(get_sorted_positions(
    conn,
    list_id,
    Some(exclude_card_id),
  ))
  let count = list.length(positions)
  case count {
    0 -> Ok(gap)
    _ -> {
      case target_index {
        0 -> {
          let assert Ok(#(_, first_pos)) = list.first(positions)
          Ok(first_pos /. 2.0)
        }
        idx if idx >= count -> {
          let assert Ok(#(_, last_pos)) = list.last(positions)
          Ok(last_pos +. gap)
        }
        idx -> {
          let assert Ok(#(_, prev_pos)) = get_at(positions, idx - 1)
          let assert Ok(#(_, next_pos)) = get_at(positions, idx)
          let new_pos = { prev_pos +. next_pos } /. 2.0
          let current_gap = float.absolute_value(next_pos -. prev_pos)
          case current_gap <. min_gap {
            True -> {
              use _ <- result.try(rebalance_list(conn, list_id))
              calculate_move_position(conn, list_id, target_index, exclude_card_id)
            }
            False -> Ok(new_pos)
          }
        }
      }
    }
  }
}

pub fn rebalance_list(conn: Connection, list_id: Int) -> Result(Nil, Error) {
  use positions <- result.try(get_sorted_positions(conn, list_id, None))
  list.index_fold(positions, Ok(Nil), fn(acc, item, index) {
    use _ <- result.try(acc)
    let #(id, _) = item
    let new_pos = int.to_float(index + 1) *. gap
    sqlight.query(
      "UPDATE cards SET position = ?1 WHERE id = ?2",
      on: conn,
      with: [sqlight.float(new_pos), sqlight.text(id)],
      expecting: decode.success(Nil),
    )
    |> result.map(fn(_) { Nil })
  })
}

fn get_sorted_positions(
  conn: Connection,
  list_id: Int,
  exclude_id: option.Option(String),
) -> Result(List(#(String, Float)), Error) {
  let #(sql, params) = case exclude_id {
    None -> #(
      "SELECT id, position FROM cards WHERE list_id = ?1 ORDER BY position",
      [sqlight.int(list_id)],
    )
    Some(id) -> #(
      "SELECT id, position FROM cards WHERE list_id = ?1 AND id != ?2 ORDER BY position",
      [sqlight.int(list_id), sqlight.text(id)],
    )
  }
  let decoder = {
    use id <- decode.field(0, decode.string)
    use position <- decode.field(1, decode.float)
    decode.success(#(id, position))
  }
  sqlight.query(sql, on: conn, with: params, expecting: decoder)
}

fn get_at(items: List(a), index: Int) -> Result(a, Nil) {
  case items, index {
    [first, ..], 0 -> Ok(first)
    [_, ..rest], n if n > 0 -> get_at(rest, n - 1)
    _, _ -> Error(Nil)
  }
}
