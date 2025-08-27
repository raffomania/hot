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

  describe "list-based archive functionality" do
    test "cards are created with archived_at=nil by default" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "Test Card", list_id: 1})

      assert card.archived_at == nil
    end

    test "can mark card as finished" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "To Finish", list_id: 1})

      assert {:ok, finished_card} =
               card
               |> Ash.Changeset.for_update(:mark_finished)
               |> Ash.update()

      assert finished_card.list_id == 3
      assert finished_card.archived_at != nil
    end

    test "can mark card as cancelled" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "To Cancel", list_id: 1})

      assert {:ok, cancelled_card} =
               card
               |> Ash.Changeset.for_update(:mark_cancelled)
               |> Ash.update()

      assert cancelled_card.list_id == 4
      assert cancelled_card.archived_at != nil
    end

    test "can archive a card with finished status" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "To Archive", list_id: 1})

      assert {:ok, archived_card} =
               card
               |> Ash.Changeset.for_update(:archive, %{status: "finished"})
               |> Ash.update()

      assert archived_card.list_id == 3
      assert archived_card.archived_at != nil
    end

    test "can archive a card with cancelled status" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "To Archive", list_id: 1})

      assert {:ok, archived_card} =
               card
               |> Ash.Changeset.for_update(:archive, %{status: "cancelled"})
               |> Ash.update()

      assert archived_card.list_id == 4
      assert archived_card.archived_at != nil
    end

    test "archive action validates status parameter" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "To Archive", list_id: 1})

      assert {:error, error} =
               card
               |> Ash.Changeset.for_update(:archive, %{status: "invalid"})
               |> Ash.update()

      assert error.errors
             |> Enum.any?(fn e -> String.contains?(to_string(e.message), "finished") end)
    end

    test "can unarchive a finished card" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "To Unarchive", list_id: 2})

      # First finish it
      assert {:ok, finished_card} =
               card
               |> Ash.Changeset.for_update(:mark_finished)
               |> Ash.update()

      # Then unarchive it
      assert {:ok, unarchived_card} =
               finished_card
               |> Ash.Changeset.for_update(:unarchive)
               |> Ash.update()

      assert unarchived_card.archived_at == nil
      # Should move to "new" list (list_id 1)
      assert unarchived_card.list_id == 1
    end

    test "can unarchive a cancelled card" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "To Unarchive", list_id: 2})

      # First cancel it
      assert {:ok, cancelled_card} =
               card
               |> Ash.Changeset.for_update(:mark_cancelled)
               |> Ash.update()

      # Then unarchive it
      assert {:ok, unarchived_card} =
               cancelled_card
               |> Ash.Changeset.for_update(:unarchive)
               |> Ash.update()

      assert unarchived_card.archived_at == nil
      # Should move to "new" list (list_id 1)
      assert unarchived_card.list_id == 1
    end

    test "active_cards query excludes finished and cancelled cards" do
      # Create some cards
      assert {:ok, card1} =
               Ash.create(Card, %{title: "Active Card", list_id: 1})

      assert {:ok, card2} =
               Ash.create(Card, %{title: "To Finish", list_id: 1})

      assert {:ok, card3} =
               Ash.create(Card, %{title: "To Cancel", list_id: 2})

      # Finish and cancel some cards
      assert {:ok, _finished_card} =
               card2
               |> Ash.Changeset.for_update(:mark_finished)
               |> Ash.update()

      assert {:ok, _cancelled_card} =
               card3
               |> Ash.Changeset.for_update(:mark_cancelled)
               |> Ash.update()

      # Query active cards
      active_cards = Ash.read!(Card, action: :active_cards)

      assert length(active_cards) == 1
      assert Enum.at(active_cards, 0).id == card1.id
    end

    test "finished_cards query returns only finished cards" do
      # Create some cards
      assert {:ok, _card1} =
               Ash.create(Card, %{title: "Active Card", list_id: 1})

      assert {:ok, card2} =
               Ash.create(Card, %{title: "To Finish", list_id: 1})

      assert {:ok, card3} =
               Ash.create(Card, %{title: "To Cancel", list_id: 1})

      # Finish one and cancel another
      assert {:ok, finished_card} =
               card2
               |> Ash.Changeset.for_update(:mark_finished)
               |> Ash.update()

      assert {:ok, _cancelled_card} =
               card3
               |> Ash.Changeset.for_update(:mark_cancelled)
               |> Ash.update()

      # Query finished cards
      finished_cards = Ash.read!(Card, action: :finished_cards)

      assert length(finished_cards) == 1
      assert Enum.at(finished_cards, 0).id == finished_card.id
    end

    test "cancelled_cards query returns only cancelled cards" do
      # Create some cards
      assert {:ok, _card1} =
               Ash.create(Card, %{title: "Active Card", list_id: 1})

      assert {:ok, card2} =
               Ash.create(Card, %{title: "To Finish", list_id: 1})

      assert {:ok, card3} =
               Ash.create(Card, %{title: "To Cancel", list_id: 1})

      # Finish one and cancel another
      assert {:ok, _finished_card} =
               card2
               |> Ash.Changeset.for_update(:mark_finished)
               |> Ash.update()

      assert {:ok, cancelled_card} =
               card3
               |> Ash.Changeset.for_update(:mark_cancelled)
               |> Ash.update()

      # Query cancelled cards
      cancelled_cards = Ash.read!(Card, action: :cancelled_cards)

      assert length(cancelled_cards) == 1
      assert Enum.at(cancelled_cards, 0).id == cancelled_card.id
    end

    test "archived_cards query returns finished and cancelled cards" do
      # Create some cards
      assert {:ok, _card1} =
               Ash.create(Card, %{title: "Active Card", list_id: 1})

      assert {:ok, card2} =
               Ash.create(Card, %{title: "To Finish", list_id: 1})

      assert {:ok, card3} =
               Ash.create(Card, %{title: "To Cancel", list_id: 1})

      # Finish one and cancel another
      assert {:ok, finished_card} =
               card2
               |> Ash.Changeset.for_update(:mark_finished)
               |> Ash.update()

      assert {:ok, cancelled_card} =
               card3
               |> Ash.Changeset.for_update(:mark_cancelled)
               |> Ash.update()

      # Query archived cards
      archived_cards = Ash.read!(Card, action: :archived_cards)

      assert length(archived_cards) == 2
      card_ids = Enum.map(archived_cards, & &1.id)
      assert finished_card.id in card_ids
      assert cancelled_card.id in card_ids
    end

    test "primary read action returns all cards including archived" do
      # Create some cards
      assert {:ok, _card1} =
               Ash.create(Card, %{title: "Active Card", list_id: 1})

      assert {:ok, card2} =
               Ash.create(Card, %{title: "To Finish", list_id: 1})

      # Finish one card
      assert {:ok, _finished_card} =
               card2
               |> Ash.Changeset.for_update(:mark_finished)
               |> Ash.update()

      # Query all cards using primary read action
      all_cards = Ash.read!(Card)

      assert length(all_cards) == 2
    end

    test "finished and cancelled cards do not affect position calculations for active cards" do
      # Create 3 cards in the same list
      assert {:ok, _card1} =
               Ash.create(Card, %{title: "First", list_id: 1})

      assert {:ok, card2} =
               Ash.create(Card, %{title: "Second", list_id: 1})

      assert {:ok, card3} =
               Ash.create(Card, %{title: "Third", list_id: 1})

      # Finish the middle card
      assert {:ok, _finished_card} =
               card2
               |> Ash.Changeset.for_update(:mark_finished)
               |> Ash.update()

      # Create a new card in the active lists - it should get positioned correctly
      assert {:ok, _new_card} =
               Ash.create(Card, %{title: "New Card", list_id: 1})

      # Get all active cards in order
      active_cards =
        Card
        |> Ash.Query.for_read(:active_cards)
        |> Ash.Query.filter(list_id == 1)
        |> Ash.Query.sort(position: :asc)
        |> Ash.read!()

      # Should only have 3 active cards: card1, card3, new_card
      assert length(active_cards) == 3

      # Positions should be: 10.0, 30.0, 40.0 (the new card gets the next available position)
      assert Enum.at(active_cards, 0).title == "First"
      assert Enum.at(active_cards, 0).position == 10.0
      assert Enum.at(active_cards, 1).title == "Third"
      assert Enum.at(active_cards, 1).position == 30.0
      assert Enum.at(active_cards, 2).title == "New Card"
      assert Enum.at(active_cards, 2).position == 40.0

      # Now test moving a card - it should ignore finished cards in position calculations
      assert {:ok, moved_card} =
               card3
               |> Ash.Changeset.for_update(:move_to_position, %{
                 new_list_id: 1,
                 # Move to beginning
                 target_index: 0
               })
               |> Ash.update()

      # The moved card should get position between 0 and card1 (10.0), so 5.0
      assert moved_card.position == 5.0
    end
  end
end
