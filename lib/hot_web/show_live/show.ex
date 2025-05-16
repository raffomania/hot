defmodule HotWeb.ShowLive.Show do
  use HotWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Show {@show.id}
        <:subtitle>This is a show record from your database.</:subtitle>
      </.header>

      <.list>
        <:item title="Id">{@show.id}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:show, Ash.get!(Hot.Trakt.Show, id))}
  end

  defp page_title(:show), do: "Show Show"
  defp page_title(:edit), do: "Edit Show"
end
