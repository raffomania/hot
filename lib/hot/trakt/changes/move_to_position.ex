defmodule Hot.Trakt.Changes.MoveToPosition do
  @moduledoc """
  Ash change that handles moving a card to a new position and/or list.

  This change automatically calculates the new fractional position based on
  the target list and index, handling both within-list and between-list moves.
  """

  use Ash.Resource.Change
  alias Hot.Trakt.Card
  alias Hot.Trakt.Changes.AssignPosition

  @impl true
  def change(changeset, _opts, _context) do
    new_list_id = Ash.Changeset.get_argument(changeset, :new_list_id)
    target_index = Ash.Changeset.get_argument(changeset, :target_index)

    if new_list_id && target_index != nil do
      # Get the card being moved to exclude it from position calculations
      card_id = changeset.data.id
      new_position = calculate_position_for_move(new_list_id, target_index, card_id)

      changeset
      |> Ash.Changeset.change_attribute(:list_id, new_list_id)
      |> Ash.Changeset.change_attribute(:position, new_position)
    else
      changeset
    end
  end

  defp calculate_position_for_move(list_id, target_index, exclude_card_id) do
    existing_cards =
      Card
      |> Ash.Query.filter(list_id == ^list_id and id != ^exclude_card_id and archived == false)
      |> Ash.Query.sort(position: :asc)
      |> Ash.read!()

    # Use fractional position logic from AssignPosition
    case AssignPosition.calculate_fractional_position(existing_cards, target_index) do
      {:ok, position} ->
        position

      {:rebalance_needed} ->
        AssignPosition.rebalance_list(list_id)

        existing_cards =
          Card
          |> Ash.Query.filter(
            list_id == ^list_id and id != ^exclude_card_id and archived == false
          )
          |> Ash.Query.sort(position: :asc)
          |> Ash.read!()

        {:ok, position} =
          AssignPosition.calculate_fractional_position(existing_cards, target_index)

        position
    end
  end
end
