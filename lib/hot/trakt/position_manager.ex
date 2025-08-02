defmodule Hot.Trakt.PositionManager do
  @moduledoc """
  Manages fractional positions for cards with lazy rebalancing.

  This module provides efficient card positioning using fractional numbers,
  allowing single-operation moves in most cases with automatic rebalancing
  when positions get too close together.
  """

  alias Hot.Trakt.Card

  @min_position_gap 0.001

  @doc """
  Calculates the new position for a card being moved to a specific index in a list.

  Returns the new fractional position that should be assigned to the card.
  If positions are too close together, triggers rebalancing first.
  """
  def calculate_new_position(list_id, target_index, moved_card_id \\ nil) do
    cards_in_list = get_sorted_cards_in_list(list_id, moved_card_id)

    case calculate_fractional_position(cards_in_list, target_index) do
      {:ok, position} ->
        position

      {:rebalance_needed} ->
        rebalance_list_to_integers(list_id)
        # Retry after rebalancing
        cards_in_list = get_sorted_cards_in_list(list_id, moved_card_id)
        {:ok, position} = calculate_fractional_position(cards_in_list, target_index)
        position
    end
  end

  @doc """
  Moves a card to a new position using fractional positioning.
  This is a single database operation in most cases.
  """
  def move_card(card, new_list_id, target_index) do
    new_position = calculate_new_position(new_list_id, target_index, card.id)

    Ash.update(card, %{
      list_id: new_list_id,
      position: new_position
    })
  end

  defp get_sorted_cards_in_list(list_id, exclude_card_id \\ nil) do
    Card
    |> Ash.Query.sort(position: :asc)
    |> Ash.read!()
    |> Enum.filter(fn card ->
      card.list_id == list_id && card.id != exclude_card_id
    end)
  end

  defp calculate_fractional_position(cards, target_index) do
    cond do
      # Inserting at the beginning
      target_index == 0 ->
        case cards do
          [] ->
            {:ok, 10.0}

          [first_card | _] ->
            if first_card.position > @min_position_gap do
              {:ok, first_card.position / 2.0}
            else
              {:rebalance_needed}
            end
        end

      # Inserting at the end
      target_index >= length(cards) ->
        case List.last(cards) do
          nil -> {:ok, 0.0}
          last_card -> {:ok, last_card.position + 10.0}
        end

      # Inserting in the middle
      true ->
        prev_card = Enum.at(cards, target_index - 1)
        next_card = Enum.at(cards, target_index)

        gap = next_card.position - prev_card.position

        if gap > @min_position_gap * 2 do
          new_position = prev_card.position + gap / 2.0
          {:ok, new_position}
        else
          {:rebalance_needed}
        end
    end
  end

  defp rebalance_list_to_integers(list_id) do
    cards_in_list = get_sorted_cards_in_list(list_id)

    # Reset positions to integers with gaps (10.0, 20.0, etc.)
    cards_in_list
    |> Enum.with_index()
    |> Enum.each(fn {card, index} ->
      Ash.update!(card, %{position: (index + 1) * 10.0})
    end)
  end
end
