defmodule HotWeb.ShowLive.Show do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    show = Ash.get!(Hot.Trakt.Show, id)

    {:noreply,
     socket
     |> assign(:page_title, show.title)
     |> assign(:show, show)}
  end
end
