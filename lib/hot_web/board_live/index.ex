defmodule HotWeb.BoardLive.Index do
  use HotWeb, :live_view

  alias Hot.Trakt.{Card, BoardLists}
  import HotWeb.CoreComponents, only: [linkify_text: 1]

  @board_topic "board:updates"

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="flex justify-center px-4 py-8 space-x-1 overflow-x-auto"
      id="board-container"
      phx-hook="BoardContainer"
    >
      <div id="keyboard-handler" phx-hook="DropzoneKeyboard" style="display: none;"></div>
      <div
        :for={{list_id, list_config} <- @lists}
        class="flex flex-col p-4 pb-10 rounded-md bg-neutral-100 min-w-72 max-w-72"
        id={"list-#{list_id}"}
        data-list-id={list_id}
      >
        <div class="flex items-center justify-between mb-4">
          <h3 class="px-1 font-semibold">
            {list_config.title}
          </h3>
          <button phx-click="add_card" phx-value-list-id={list_id}>
            + Add Card
          </button>
        </div>

        <div class="flex-1 space-y-2 cards-container">
          <div
            :for={card <- cards_for_list(@cards, list_id)}
            class="p-4 bg-white border rounded-md border-neutral-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
            data-card-id={card.id}
            id={"card-#{card.id}"}
            tabindex="0"
            role="button"
            aria-label={"Card: #{card.title || "Untitled"} - Press Shift+F to finish, Shift+C to cancel, or Shift+Delete to archive"}
          >
            
    <!-- Card Title -->
            <%= if @editing_card_id == card.id and @editing_card_field == :title do %>
              <form phx-submit="save_card_field" phx-click-away="cancel_edit_card">
                <input type="hidden" name="card_id" value={card.id} />
                <input type="hidden" name="field" value="title" />
                <input
                  type="text"
                  name="value"
                  value={card.title}
                  class="w-full px-2 font-medium bg-transparent border border-black focus:outline-none"
                  phx-hook="FocusAndSelect"
                  id={"edit-card-title-#{card.id}"}
                  phx-key="Escape"
                  phx-keyup="cancel_edit_card"
                />
              </form>
            <% else %>
              <h4
                class={"mb-2 #{if is_nil(card.title) or card.title == "", do: "opacity-50 italic", else: ""}"}
                phx-click="edit_card_field"
                phx-value-card-id={card.id}
                phx-value-field="title"
              >
                {if is_nil(card.title) or card.title == "",
                  do: "Enter card title...",
                  else: card.title}
              </h4>
            <% end %>
            
    <!-- Card Description -->
            <%= if card.description || (@editing_card_id == card.id and @editing_card_field == :description) do %>
              <%= if @editing_card_id == card.id and @editing_card_field == :description do %>
                <form phx-submit="save_card_field" class="mt-1">
                  <input type="hidden" name="card_id" value={card.id} />
                  <input type="hidden" name="field" value="description" />
                  <textarea
                    name="value"
                    class="w-full px-2 text-sm resize-none"
                    rows="2"
                    phx-hook="TextareaAutoSave"
                    id={"edit-card-description-#{card.id}"}
                    phx-key="Escape"
                    phx-keyup="cancel_edit_card"
                  ><%= card.description || "" %></textarea>
                </form>
              <% else %>
                <p
                  class="text-sm break-words"
                  phx-click="edit_card_field"
                  phx-value-card-id={card.id}
                  phx-value-field="description"
                >
                  {linkify_text(card.description)}
                </p>
              <% end %>
            <% else %>
              <!-- Add description link when no description exists -->
              <p
                class="text-sm italic opacity-50"
                phx-click="edit_card_field"
                phx-value-card-id={card.id}
                phx-value-field="description"
              >
                Add description...
              </p>
            <% end %>

            <div :if={card.show} class="mt-2 text-xs">
              📺 {card.show.title}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Finished Dropzone (Green, Bottom Right) -->
    <div
      id="finished-dropzone"
      class="fixed bottom-4 right-4 z-50 flex flex-col items-center justify-center w-32 h-32 sm:w-40 sm:h-40 md:w-48 md:h-48 transition-all duration-200 transform scale-75 border-4 border-green-400 border-dashed rounded-lg opacity-0 pointer-events-none bg-green-50"
      phx-hook="FinishedDropzone"
      role="region"
      aria-label="Finished dropzone - Drop cards here to mark them as finished"
      aria-live="polite"
      aria-describedby="finished-help-text"
    >
      <svg
        class="w-6 h-6 sm:w-7 sm:h-7 md:w-8 md:h-8 mb-1 sm:mb-2 text-green-600"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
        aria-hidden="true"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7">
        </path>
      </svg>
      <span class="text-xs sm:text-sm font-medium text-green-600">Finished</span>
    </div>

    <!-- Cancelled Dropzone (Red, Bottom Left) -->
    <div
      id="cancelled-dropzone"
      class="fixed bottom-4 left-4 z-50 flex flex-col items-center justify-center w-32 h-32 sm:w-40 sm:h-40 md:w-48 md:h-48 transition-all duration-200 transform scale-75 border-4 border-red-400 border-dashed rounded-lg opacity-0 pointer-events-none bg-red-50"
      phx-hook="CancelledDropzone"
      role="region"
      aria-label="Cancelled dropzone - Drop cards here to mark them as cancelled"
      aria-live="polite"
      aria-describedby="cancelled-help-text"
    >
      <svg
        class="w-6 h-6 sm:w-7 sm:h-7 md:w-8 md:h-8 mb-1 sm:mb-2 text-red-600"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
        aria-hidden="true"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12">
        </path>
      </svg>
      <span class="text-xs sm:text-sm font-medium text-red-600">Cancelled</span>
    </div>

    <!-- Hidden help text for accessibility -->
    <div id="finished-help-text" class="sr-only">
      When dragging a card, drop it on the finished area to mark it as finished. Use Shift+F keyboard shortcut to finish the currently focused card.
    </div>
    <div id="cancelled-help-text" class="sr-only">
      When dragging a card, drop it on the cancelled area to mark it as cancelled. Use Shift+C keyboard shortcut to cancel the currently focused card.
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
      |> assign(:page_title, "Board")
      |> assign(:current_page, :board)
      |> assign(:editing_card_id, nil)
      |> assign(:editing_card_field, nil)
      |> load_board_data()

    {:ok, socket}
  end

  @impl true
  def handle_event("add_card", %{"list-id" => list_id_str}, socket) do
    list_id = String.to_integer(list_id_str)

    case Ash.create(Card, %{
           title: "",
           description: nil,
           list_id: list_id
         }) do
      {:ok, card} ->
        # Broadcast to all connected clients
        Phoenix.PubSub.broadcast(
          Hot.PubSub,
          @board_topic,
          {:board_updated, %{action: :card_created, card: card}}
        )

        socket =
          socket
          |> assign(:editing_card_id, card.id)
          |> assign(:editing_card_field, :title)
          |> load_board_data()

        {:noreply, socket}

      {:error, _error} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "move_card",
        %{
          "card_id" => card_id,
          "from_list_id" => _from_list_id,
          "to_list_id" => to_list_id_str,
          "new_position" => new_position
        },
        socket
      ) do
    to_list_id = String.to_integer(to_list_id_str)

    with {:ok, card} <- Ash.get(Card, card_id),
         {:ok, updated_card} <-
           card
           |> Ash.Changeset.for_update(:move_to_position, %{
             new_list_id: to_list_id,
             target_index: new_position
           })
           |> Ash.update() do
      # Broadcast to all connected clients
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        @board_topic,
        {:board_updated, %{action: :card_moved, card: updated_card}}
      )

      {:noreply, load_board_data(socket)}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("edit_card_field", %{"card-id" => card_id, "field" => field}, socket) do
    socket =
      socket
      |> assign(:editing_card_id, card_id)
      |> assign(:editing_card_field, String.to_atom(field))

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_edit_card", _params, socket) do
    {:noreply, clear_editing_state(socket)}
  end

  @impl true
  def handle_event(
        "save_card_field",
        %{"card_id" => card_id, "field" => field, "value" => value},
        socket
      ) do
    with {:ok, card} <- Ash.get(Card, card_id),
         field_atom = String.to_atom(field),
         update_params = %{field_atom => if(value == "", do: nil, else: value)},
         {:ok, updated_card} <- Ash.update(card, update_params) do
      # Broadcast to all connected clients
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        @board_topic,
        {:board_updated, %{action: :card_updated, card: updated_card}}
      )

      socket =
        socket
        |> clear_editing_state()
        |> load_board_data()

      {:noreply, socket}
    else
      _ -> {:noreply, clear_editing_state(socket)}
    end
  end

  @impl true
  def handle_event("finish_card", %{"card_id" => card_id}, socket)
      when is_binary(card_id) and card_id != "" do
    with {:ok, card} <- Ash.get(Card, card_id),
         {:ok, finished_card} <-
           card
           |> Ash.Changeset.for_update(:mark_finished)
           |> Ash.update() do
      # Broadcast to all connected clients
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        @board_topic,
        {:board_updated, %{action: :card_finished, card: finished_card}}
      )

      # Also broadcast to archive page if it's open
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        "archive:updates",
        {:card_finished, finished_card}
      )

      {:noreply, load_board_data(socket)}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("finish_card", _params, socket) do
    # Handle malformed parameters gracefully
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_card", %{"card_id" => card_id}, socket)
      when is_binary(card_id) and card_id != "" do
    with {:ok, card} <- Ash.get(Card, card_id),
         {:ok, cancelled_card} <-
           card
           |> Ash.Changeset.for_update(:mark_cancelled)
           |> Ash.update() do
      # Broadcast to all connected clients
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        @board_topic,
        {:board_updated, %{action: :card_cancelled, card: cancelled_card}}
      )

      # Also broadcast to archive page if it's open
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        "archive:updates",
        {:card_cancelled, cancelled_card}
      )

      {:noreply, load_board_data(socket)}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel_card", _params, socket) do
    # Handle malformed parameters gracefully
    {:noreply, socket}
  end

  # Legacy handler for backward compatibility
  @impl true
  def handle_event("archive_card", %{"card_id" => card_id}, socket)
      when is_binary(card_id) and card_id != "" do
    handle_event("finish_card", %{"card_id" => card_id}, socket)
  end

  @impl true
  def handle_event("archive_card", _params, socket) do
    # Handle malformed parameters gracefully
    {:noreply, socket}
  end

  @impl true
  def handle_info({:board_updated, _data}, socket) do
    socket = load_board_data(socket)
    {:noreply, socket}
  end

  defp load_board_data(socket) do
    lists = BoardLists.get_active_lists()

    cards =
      Card
      |> Ash.Query.for_read(:active_cards)
      |> Ash.Query.sort(position: :asc)
      |> Ash.Query.load(:show)
      |> Ash.read!()

    socket
    |> assign(:lists, lists)
    |> assign(:cards, cards)
  end

  defp cards_for_list(cards, list_id) do
    Enum.filter(cards, &(&1.list_id == list_id))
  end

  defp clear_editing_state(socket) do
    socket
    |> assign(:editing_card_id, nil)
    |> assign(:editing_card_field, nil)
  end
end
