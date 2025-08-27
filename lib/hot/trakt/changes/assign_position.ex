defmodule Hot.Trakt.Changes.AssignPosition do
  @moduledoc """
  Ash change that automatically assigns fractional positions to new cards.

  This change always adds new cards to the end of the specified list,
  calculating the next available position using a simple increment.
  """

  use Ash.Resource.Change
  alias Hot.Trakt.Card

  @impl true
  def change(changeset, _opts, _context) do
    list_id = Ash.Changeset.get_attribute(changeset, :list_id)

    if list_id do
      new_position = calculate_end_position(list_id)
      Ash.Changeset.change_attribute(changeset, :position, new_position)
    else
      changeset
    end
  end

  defp calculate_end_position(list_id) do
    case get_last_position_in_list(list_id) do
      # First card in list
      nil -> 10.0
      # Add with gap
      last_position -> last_position + 10.0
    end
  end

  defp get_last_position_in_list(list_id) do
    Card
    |> Ash.Query.filter(list_id == ^list_id and archived == false)
    |> Ash.Query.sort(position: :desc)
    |> Ash.Query.limit(1)
    |> Ash.read!()
    |> case do
      [] -> nil
      [last_card] -> last_card.position
    end
  end

  @min_position_gap 0.001

  @doc """
  Calculates fractional position for inserting at a specific index.
  Returns {:ok, position} or {:rebalance_needed} if positions are too close.
  """
  def calculate_fractional_position(cards, target_index) do
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

  @doc """
  Rebalances positions in a list to integers with gaps.
  """
  def rebalance_list(list_id) do
    cards_in_list =
      Card
      |> Ash.Query.filter(list_id == ^list_id and archived == false)
      |> Ash.Query.sort(position: :asc)
      |> Ash.read!()

    # Reset positions to integers with gaps (10.0, 20.0, etc.)
    cards_in_list
    |> Enum.with_index()
    |> Enum.each(fn {card, index} ->
      Ash.update!(card, %{position: (index + 1) * 10.0})
    end)
  end
end
