defmodule Hot.Trakt.Changes.RebalancePositions do
  @moduledoc """
  Ash change that handles bulk rebalancing of positions within a list.

  This change resets all positions in a list to evenly spaced integer values,
  providing clean spacing for future fractional positioning operations.
  """

  use Ash.Resource.Change
  alias Hot.Trakt.Card

  @impl true
  def change(changeset, _opts, _context) do
    list_id = Ash.Changeset.get_argument(changeset, :list_id)

    if list_id do
      rebalance_list_positions(list_id)
    end

    # This change doesn't modify the current record
    changeset
  end

  defp rebalance_list_positions(list_id) do
    cards_in_list =
      Card
      |> Ash.Query.filter(list_id == ^list_id)
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
