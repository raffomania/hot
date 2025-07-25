defmodule HotWeb.BoardLive.Index do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-center">
      <h2 class="text-2xl font-bold">Board</h2>
      <p class="mt-4 text-gray-600">Coming soon...</p>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Board")
      |> assign(:current_page, :board)

    {:ok, socket}
  end
end
