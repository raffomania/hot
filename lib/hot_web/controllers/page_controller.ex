defmodule HotWeb.PageController do
  use HotWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/shows")
  end
end
