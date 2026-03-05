pub type BoardList {
  BoardList(id: Int, title: String, position: Int)
}

pub fn get_all() -> List(BoardList) {
  [
    BoardList(id: 1, title: "new", position: 1),
    BoardList(id: 2, title: "watching", position: 2),
    BoardList(id: 3, title: "finished", position: 3),
    BoardList(id: 4, title: "cancelled", position: 4),
  ]
}

pub fn get_title(list_id: Int) -> String {
  case list_id {
    1 -> "new"
    2 -> "watching"
    3 -> "finished"
    4 -> "cancelled"
    _ -> "unknown"
  }
}

pub fn active_list_ids() -> List(Int) {
  [1, 2]
}

pub fn is_valid(list_id: Int) -> Bool {
  list_id >= 1 && list_id <= 4
}
