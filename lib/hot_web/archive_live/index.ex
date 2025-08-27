defmodule HotWeb.ArchiveLive.Index do
  use HotWeb, :live_view

  alias Hot.Trakt.Card
  import HotWeb.CoreComponents, only: [linkify_text: 1]

  @board_topic "board:updates"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-8 mx-auto max-w-4xl">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold">Archive</h1>
        <a href={~p"/board"} class="text-blue-600 underline">← Back to Board</a>
      </div>

      <!-- Finished Shows Section -->
      <div class="mb-8">
        <div class="flex items-center mb-4">
          <h2 class="text-xl font-semibold text-green-700">✅ Finished Shows</h2>
          <span class="ml-2 px-2 py-1 bg-green-100 text-green-700 text-sm rounded-full">
            {length(@finished_cards)}
          </span>
        </div>
        
        <%= if Enum.empty?(@finished_cards) do %>
          <div class="text-center py-8 bg-green-50 rounded-lg border border-green-200">
            <p class="text-green-600 text-lg">No finished shows yet.</p>
            <p class="text-green-500 text-sm mt-1">Shows you complete will appear here.</p>
          </div>
        <% else %>
          <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div
              :for={card <- @finished_cards}
              class="p-4 bg-white border rounded-lg border-green-200 hover:shadow-md transition-shadow"
            >
              <!-- Card Title -->
              <h3 class={[
                "font-medium mb-2",
                if(is_nil(card.title) or card.title == "", do: "opacity-50 italic", else: "")
              ]}>
                {if is_nil(card.title) or card.title == "",
                  do: "Untitled card",
                  else: card.title}
              </h3>
              
              <!-- Card Description -->
              <%= if card.description do %>
                <p class="text-sm text-gray-600 break-words mb-3">
                  {linkify_text(card.description)}
                </p>
              <% end %>
              
              <!-- Show Information -->
              <div :if={card.show} class="text-xs text-gray-500 mb-3">
                📺 {card.show.title}
              </div>
              
              <!-- Archive Date and Actions -->
              <div class="flex items-center justify-between text-xs text-gray-400">
                <span class="text-green-600">
                  Finished {format_date(card.archived_at)}
                </span>
                <button
                  phx-click="unarchive_card"
                  phx-value-card-id={card.id}
                  class="text-blue-600 hover:text-blue-800 font-medium"
                >
                  Restore
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Cancelled Shows Section -->
      <div>
        <div class="flex items-center mb-4">
          <h2 class="text-xl font-semibold text-red-700">❌ Cancelled Shows</h2>
          <span class="ml-2 px-2 py-1 bg-red-100 text-red-700 text-sm rounded-full">
            {length(@cancelled_cards)}
          </span>
        </div>
        
        <%= if Enum.empty?(@cancelled_cards) do %>
          <div class="text-center py-8 bg-red-50 rounded-lg border border-red-200">
            <p class="text-red-600 text-lg">No cancelled shows yet.</p>
            <p class="text-red-500 text-sm mt-1">Shows you drop will appear here.</p>
          </div>
        <% else %>
          <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div
              :for={card <- @cancelled_cards}
              class="p-4 bg-white border rounded-lg border-red-200 hover:shadow-md transition-shadow"
            >
              <!-- Card Title -->
              <h3 class={[
                "font-medium mb-2",
                if(is_nil(card.title) or card.title == "", do: "opacity-50 italic", else: "")
              ]}>
                {if is_nil(card.title) or card.title == "",
                  do: "Untitled card",
                  else: card.title}
              </h3>
              
              <!-- Card Description -->
              <%= if card.description do %>
                <p class="text-sm text-gray-600 break-words mb-3">
                  {linkify_text(card.description)}
                </p>
              <% end %>
              
              <!-- Show Information -->
              <div :if={card.show} class="text-xs text-gray-500 mb-3">
                📺 {card.show.title}
              </div>
              
              <!-- Archive Date and Actions -->
              <div class="flex items-center justify-between text-xs text-gray-400">
                <span class="text-red-600">
                  Cancelled {format_date(card.archived_at)}
                </span>
                <button
                  phx-click="unarchive_card"
                  phx-value-card-id={card.id}
                  class="text-blue-600 hover:text-blue-800 font-medium"
                >
                  Restore
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Hot.PubSub, @board_topic)
    end

    socket =
      socket
      |> assign(:page_title, "Archive")
      |> assign(:current_page, :archive)
      |> load_finished_cards()
      |> load_cancelled_cards()

    {:ok, socket}
  end

  @impl true
  def handle_event("unarchive_card", %{"card-id" => card_id}, socket) do
    with {:ok, card} <- Ash.get(Card, card_id),
         {:ok, updated_card} <- Ash.update(card, %{}, action: :unarchive) do
      # Broadcast to all connected clients
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        @board_topic,
        {:board_updated, %{action: :card_unarchived, card: updated_card}}
      )

      socket = socket |> load_finished_cards() |> load_cancelled_cards()
      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:board_updated, %{action: :card_archived}}, socket) do
    socket = socket |> load_finished_cards() |> load_cancelled_cards()
    {:noreply, socket}
  end

  @impl true
  def handle_info({:board_updated, %{action: :card_unarchived}}, socket) do
    socket = socket |> load_finished_cards() |> load_cancelled_cards()
    {:noreply, socket}
  end

  @impl true
  def handle_info({:board_updated, %{action: :card_finished}}, socket) do
    socket = socket |> load_finished_cards() |> load_cancelled_cards()
    {:noreply, socket}
  end

  @impl true
  def handle_info({:board_updated, %{action: :card_cancelled}}, socket) do
    socket = socket |> load_finished_cards() |> load_cancelled_cards()
    {:noreply, socket}
  end

  @impl true
  def handle_info({:board_updated, _data}, socket) do
    # Ignore other board updates
    {:noreply, socket}
  end

  defp load_finished_cards(socket) do
    finished_cards =
      Card
      |> Ash.Query.for_read(:finished_cards)
      |> Ash.Query.sort(archived_at: :desc)
      |> Ash.Query.load(:show)
      |> Ash.read!()

    assign(socket, :finished_cards, finished_cards)
  end

  defp load_cancelled_cards(socket) do
    cancelled_cards =
      Card
      |> Ash.Query.for_read(:cancelled_cards)
      |> Ash.Query.sort(archived_at: :desc)
      |> Ash.Query.load(:show)
      |> Ash.read!()

    assign(socket, :cancelled_cards, cancelled_cards)
  end

  defp format_date(nil), do: "Unknown"

  defp format_date(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end
end
