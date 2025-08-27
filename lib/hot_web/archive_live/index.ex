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

      <%= if Enum.empty?(@archived_cards) do %>
        <div class="text-center py-12">
          <p class="text-gray-500 text-lg">No archived cards yet.</p>
          <p class="text-gray-400 text-sm mt-2">Cards you archive will appear here.</p>
        </div>
      <% else %>
        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <div
            :for={card <- @archived_cards}
            class="p-4 bg-white border rounded-lg border-gray-200 hover:shadow-md transition-shadow"
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
              <span>
                Archived {format_date(card.archived_at)}
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
      |> load_archived_cards()

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

      socket = load_archived_cards(socket)
      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:board_updated, %{action: :card_archived}}, socket) do
    socket = load_archived_cards(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:board_updated, %{action: :card_unarchived}}, socket) do
    socket = load_archived_cards(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:board_updated, _data}, socket) do
    # Ignore other board updates
    {:noreply, socket}
  end

  defp load_archived_cards(socket) do
    archived_cards =
      Card
      |> Ash.Query.for_read(:archived_cards)
      |> Ash.Query.sort(archived_at: :desc)
      |> Ash.Query.load(:show)
      |> Ash.read!()

    assign(socket, :archived_cards, archived_cards)
  end

  defp format_date(nil), do: "Unknown"

  defp format_date(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end
end
