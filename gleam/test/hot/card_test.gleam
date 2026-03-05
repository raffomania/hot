import gleam/option.{None, Some}
import gleeunit/should
import hot/database
import hot/models/card
import sqlight

fn setup() -> sqlight.Connection {
  let assert Ok(conn) = sqlight.open(":memory:")
  let assert Ok(_) = database.migrate(conn)
  conn
}

pub fn create_card_test() {
  let conn = setup()
  let assert Ok(c) = card.create(conn, "Test Show", None, 1)
  should.equal(c.title, "Test Show")
  should.equal(c.description, None)
  should.equal(c.list_id, 1)
  should.equal(c.position, 10.0)
  should.not_equal(c.id, "")
  should.not_equal(c.inserted_at, "")
  should.not_equal(c.updated_at, "")
}

pub fn create_card_with_description_test() {
  let conn = setup()
  let assert Ok(c) = card.create(conn, "Show", Some("A description"), 2)
  should.equal(c.description, Some("A description"))
  should.equal(c.list_id, 2)
}

pub fn get_card_test() {
  let conn = setup()
  let assert Ok(created) = card.create(conn, "Find Me", None, 1)
  let assert Ok(Some(found)) = card.get(conn, created.id)
  should.equal(found.id, created.id)
  should.equal(found.title, "Find Me")
}

pub fn get_card_not_found_test() {
  let conn = setup()
  let assert Ok(result) = card.get(conn, "nonexistent-id")
  should.equal(result, None)
}

pub fn list_active_cards_test() {
  let conn = setup()
  let assert Ok(_) = card.create(conn, "New Show", None, 1)
  let assert Ok(_) = card.create(conn, "Watching Show", None, 2)
  let assert Ok(_) = card.create(conn, "Finished Show", None, 3)
  let assert Ok(active) = card.list_active(conn)
  should.equal(list_length(active), 2)
}

pub fn update_card_test() {
  let conn = setup()
  let assert Ok(created) = card.create(conn, "Old Title", None, 1)
  let assert Ok(Some(updated)) =
    card.update(conn, created.id, "New Title", Some("New desc"))
  should.equal(updated.title, "New Title")
  should.equal(updated.description, Some("New desc"))
  should.equal(updated.id, created.id)
}

pub fn delete_card_test() {
  let conn = setup()
  let assert Ok(created) = card.create(conn, "Delete Me", None, 1)
  let assert Ok(True) = card.delete(conn, created.id)
  let assert Ok(None) = card.get(conn, created.id)
}

pub fn delete_nonexistent_test() {
  let conn = setup()
  let assert Ok(False) = card.delete(conn, "no-such-id")
}

pub fn mark_finished_test() {
  let conn = setup()
  let assert Ok(created) = card.create(conn, "Finish Me", None, 1)
  let assert Ok(Some(finished)) = card.mark_finished(conn, created.id)
  should.equal(finished.list_id, 3)
  should.not_equal(finished.archived_at, None)
}

pub fn mark_cancelled_test() {
  let conn = setup()
  let assert Ok(created) = card.create(conn, "Cancel Me", None, 2)
  let assert Ok(Some(cancelled)) = card.mark_cancelled(conn, created.id)
  should.equal(cancelled.list_id, 4)
  should.not_equal(cancelled.archived_at, None)
}

pub fn unarchive_test() {
  let conn = setup()
  let assert Ok(created) = card.create(conn, "Archive Me", None, 1)
  let assert Ok(Some(_)) = card.mark_finished(conn, created.id)
  let assert Ok(Some(unarchived)) = card.unarchive(conn, created.id)
  should.equal(unarchived.list_id, 1)
  should.equal(unarchived.archived_at, None)
  // Should get a new position at end of list 1
  should.be_true(unarchived.position >. 0.0)
}

pub fn ordering_by_position_test() {
  let conn = setup()
  let assert Ok(c1) = card.create(conn, "First", None, 1)
  let assert Ok(c2) = card.create(conn, "Second", None, 1)
  let assert Ok(c3) = card.create(conn, "Third", None, 1)
  should.be_true(c1.position <. c2.position)
  should.be_true(c2.position <. c3.position)

  let assert Ok(cards) = card.list_by_list(conn, 1)
  should.equal(list_length(cards), 3)
  let assert [first, second, third] = cards
  should.equal(first.title, "First")
  should.equal(second.title, "Second")
  should.equal(third.title, "Third")
}

pub fn list_finished_test() {
  let conn = setup()
  let assert Ok(c1) = card.create(conn, "Done Show", None, 1)
  let assert Ok(_) = card.mark_finished(conn, c1.id)
  let assert Ok(finished) = card.list_finished(conn)
  should.equal(list_length(finished), 1)
  let assert [f] = finished
  should.equal(f.title, "Done Show")
}

pub fn list_cancelled_test() {
  let conn = setup()
  let assert Ok(c1) = card.create(conn, "Cancelled Show", None, 1)
  let assert Ok(_) = card.mark_cancelled(conn, c1.id)
  let assert Ok(cancelled) = card.list_cancelled(conn)
  should.equal(list_length(cancelled), 1)
  let assert [c] = cancelled
  should.equal(c.title, "Cancelled Show")
}

fn list_length(items: List(a)) -> Int {
  do_list_length(items, 0)
}

fn do_list_length(items: List(a), acc: Int) -> Int {
  case items {
    [] -> acc
    [_, ..rest] -> do_list_length(rest, acc + 1)
  }
}
