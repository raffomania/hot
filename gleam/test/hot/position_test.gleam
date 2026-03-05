import gleam/option.{None, Some}
import gleeunit/should
import hot/database
import hot/models/card
import hot/models/position
import sqlight

fn setup() -> sqlight.Connection {
  let assert Ok(conn) = sqlight.open(":memory:")
  let assert Ok(_) = database.migrate(conn)
  conn
}

pub fn end_position_first_card_test() {
  let conn = setup()
  let assert Ok(pos) = position.assign_end_position(conn, 1)
  should.equal(pos, 10.0)
}

pub fn end_position_second_card_test() {
  let conn = setup()
  let assert Ok(_) = card.create(conn, "First", None, 1)
  let assert Ok(pos) = position.assign_end_position(conn, 1)
  should.equal(pos, 20.0)
}

pub fn end_position_third_card_test() {
  let conn = setup()
  let assert Ok(_) = card.create(conn, "First", None, 1)
  let assert Ok(_) = card.create(conn, "Second", None, 1)
  let assert Ok(pos) = position.assign_end_position(conn, 1)
  should.equal(pos, 30.0)
}

pub fn move_to_beginning_test() {
  let conn = setup()
  let assert Ok(c1) = card.create(conn, "Existing", None, 1)
  // Create a card in list 2, then move it to beginning of list 1
  let assert Ok(c2) = card.create(conn, "Mover", None, 2)
  let assert Ok(pos) =
    position.calculate_move_position(conn, 1, 0, c2.id)
  // Should be half of first card's position
  should.equal(pos, c1.position /. 2.0)
}

pub fn move_to_end_test() {
  let conn = setup()
  let assert Ok(c1) = card.create(conn, "First", None, 1)
  let assert Ok(c2) = card.create(conn, "Mover", None, 2)
  let assert Ok(pos) =
    position.calculate_move_position(conn, 1, 1, c2.id)
  // Should be last + gap
  should.equal(pos, c1.position +. position.gap)
}

pub fn move_to_middle_test() {
  let conn = setup()
  let assert Ok(c1) = card.create(conn, "First", None, 1)
  let assert Ok(c2) = card.create(conn, "Second", None, 1)
  let assert Ok(c3) = card.create(conn, "Mover", None, 2)
  let assert Ok(pos) =
    position.calculate_move_position(conn, 1, 1, c3.id)
  // Should be midpoint between c1 and c2
  should.equal(pos, { c1.position +. c2.position } /. 2.0)
}

pub fn move_to_empty_list_test() {
  let conn = setup()
  let assert Ok(c1) = card.create(conn, "Mover", None, 2)
  let assert Ok(pos) =
    position.calculate_move_position(conn, 1, 0, c1.id)
  should.equal(pos, position.gap)
}

pub fn rebalance_test() {
  let conn = setup()
  let assert Ok(_) = card.create(conn, "A", None, 1)
  let assert Ok(_) = card.create(conn, "B", None, 1)
  let assert Ok(_) = card.create(conn, "C", None, 1)
  let assert Ok(_) = position.rebalance_list(conn, 1)
  let assert Ok(cards) = card.list_by_list(conn, 1)
  let assert [a, b, c] = cards
  should.equal(a.position, 10.0)
  should.equal(b.position, 20.0)
  should.equal(c.position, 30.0)
}

pub fn move_card_to_position_test() {
  let conn = setup()
  let assert Ok(_) = card.create(conn, "A", None, 1)
  let assert Ok(_) = card.create(conn, "B", None, 1)
  let assert Ok(c) = card.create(conn, "C", None, 1)
  // Move C to beginning (index 0)
  let assert Ok(Some(moved)) = card.move_to_position(conn, c.id, 1, 0)
  should.be_true(moved.position <. 10.0)
  // Verify ordering
  let assert Ok(cards) = card.list_by_list(conn, 1)
  let assert [first, ..] = cards
  should.equal(first.title, "C")
}
