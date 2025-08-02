defmodule Hot.Trakt.CardTest do
  use Hot.DataCase, async: false

  alias Hot.Trakt.Card
  require Ash.Query

  describe "card resource" do
    test "can create a card with title and list" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "Test Card", list_id: 1})

      assert card.title == "Test Card"
      assert card.list_id == 1
      # First card gets position 10.0
      assert card.position == 10.0
    end

    test "can create a card with optional description" do
      assert {:ok, card} =
               Ash.create(Card, %{
                 title: "Test Card",
                 description: "This is a test card",
                 list_id: 2
               })

      assert card.description == "This is a test card"
      # First card gets position 10.0
      assert card.position == 10.0
    end

    test "can create a card without a title" do
      assert {:ok, card} = Ash.create(Card, %{list_id: 1})
      # When no title is provided, title field defaults to ""
      # Could be either default or nil
      assert card.title == "" || card.title == nil
      assert card.list_id == 1
      assert card.position == 10.0
    end

    test "requires a list_id" do
      assert {:error, error} = Ash.create(Card, %{title: "Test Card"})

      assert error.errors
             |> Enum.any?(fn e -> String.contains?(to_string(e.field), "list_id") end)
    end

    test "can read cards sorted by position with automatic positioning" do
      # Create first card - should get position 10.0
      assert {:ok, _card1} =
               Ash.create(Card, %{title: "First", list_id: 3})

      # Create second card - should get position 20.0 (10.0 + 10.0)
      assert {:ok, _card2} =
               Ash.create(Card, %{title: "Second", list_id: 3})

      cards =
        Card
        |> Ash.Query.filter(list_id == 3)
        |> Ash.Query.sort(position: :asc)
        |> Ash.read!()

      assert length(cards) == 2
      assert Enum.at(cards, 0).title == "First"
      assert Enum.at(cards, 0).position == 10.0
      assert Enum.at(cards, 1).title == "Second"
      assert Enum.at(cards, 1).position == 20.0
    end

    test "can update card properties but not position directly" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "Original", list_id: 4})

      assert {:ok, updated_card} =
               Ash.update(card, %{
                 title: "Updated",
                 description: "New description"
               })

      assert updated_card.title == "Updated"
      assert updated_card.description == "New description"
      # Position unchanged
      assert updated_card.position == card.position
    end

    test "can move card to different list using move_to_position action" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "Movable Card", list_id: 1})

      # Move to end of watching list (target_index larger than list size)
      assert {:ok, moved_card} =
               card
               |> Ash.Changeset.for_update(:move_to_position, %{
                 new_list_id: 2,
                 target_index: 0
               })
               |> Ash.update()

      assert moved_card.list_id == 2
      # First position in new list
      assert moved_card.position == 10.0
    end

    test "can delete a card" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "To Delete", list_id: 1})

      assert :ok = Ash.destroy(card)

      assert {:error, _} = Ash.get(Card, card.id)
    end
  end
end
