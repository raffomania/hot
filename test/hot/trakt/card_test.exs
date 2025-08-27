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

  describe "archive functionality" do
    test "cards are created with archived=false by default" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "Test Card", list_id: 1})

      assert card.archived == false
      assert card.archived_at == nil
    end

    test "can archive a card" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "To Archive", list_id: 1})

      assert {:ok, archived_card} =
               card
               |> Ash.Changeset.for_update(:archive)
               |> Ash.update()

      assert archived_card.archived == true
      assert archived_card.archived_at != nil
      assert archived_card.list_id == card.list_id
    end

    test "can unarchive a card" do
      assert {:ok, card} =
               Ash.create(Card, %{title: "To Unarchive", list_id: 2})

      # First archive it
      assert {:ok, archived_card} =
               card
               |> Ash.Changeset.for_update(:archive)
               |> Ash.update()

      # Then unarchive it
      assert {:ok, unarchived_card} =
               archived_card
               |> Ash.Changeset.for_update(:unarchive)
               |> Ash.update()

      assert unarchived_card.archived == false
      assert unarchived_card.archived_at == nil
      # Should move to "new" list (list_id 1)
      assert unarchived_card.list_id == 1
    end

    test "active_cards query excludes archived cards" do
      # Create some cards
      assert {:ok, card1} =
               Ash.create(Card, %{title: "Active Card", list_id: 1})

      assert {:ok, card2} =
               Ash.create(Card, %{title: "To Archive", list_id: 1})

      # Archive one card
      assert {:ok, _archived_card} =
               card2
               |> Ash.Changeset.for_update(:archive)
               |> Ash.update()

      # Query active cards
      active_cards = Ash.read!(Card, action: :active_cards)

      assert length(active_cards) == 1
      assert Enum.at(active_cards, 0).id == card1.id
    end

    test "archived_cards query returns only archived cards" do
      # Create some cards
      assert {:ok, _card1} =
               Ash.create(Card, %{title: "Active Card", list_id: 1})

      assert {:ok, card2} =
               Ash.create(Card, %{title: "To Archive", list_id: 1})

      # Archive one card
      assert {:ok, archived_card} =
               card2
               |> Ash.Changeset.for_update(:archive)
               |> Ash.update()

      # Query archived cards
      archived_cards = Ash.read!(Card, action: :archived_cards)

      assert length(archived_cards) == 1
      assert Enum.at(archived_cards, 0).id == archived_card.id
    end

    test "primary read action returns all cards including archived" do
      # Create some cards
      assert {:ok, _card1} =
               Ash.create(Card, %{title: "Active Card", list_id: 1})

      assert {:ok, card2} =
               Ash.create(Card, %{title: "To Archive", list_id: 1})

      # Archive one card
      assert {:ok, _archived_card} =
               card2
               |> Ash.Changeset.for_update(:archive)
               |> Ash.update()

      # Query all cards using primary read action
      all_cards = Ash.read!(Card)

      assert length(all_cards) == 2
    end
  end
end
