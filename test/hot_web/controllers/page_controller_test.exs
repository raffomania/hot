defmodule HotWeb.PageControllerTest do
  use HotWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/auth/login"
  end
end
