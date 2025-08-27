defmodule HotWeb.BoardLive.IndexTest do
  use HotWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Hot.Trakt.Card

  defp authenticate_conn(conn) do
    Plug.Test.init_test_session(conn, %{"authenticated" => true})
  end

  describe "Board LiveView" do
    test "displays the board page with predefined lists", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/board")
      assert html =~ "Board"
      assert html =~ "new"
      assert html =~ "watching"
    end

    test "displays predefined lists and cards", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card using the LiveView's add_card event
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()

      # Save the card title
      lv
      |> form("form[phx-submit='save_card_field']", %{value: "Test Card"})
      |> render_submit()

      # The card should now be visible
      html = render(lv)
      assert html =~ "new"
      assert html =~ "Test Card"
    end

    test "can add a new card to a predefined list", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Click add card button for the new list - this should immediately create a card and enter edit mode
      assert lv
             |> element("button[phx-value-list-id='1']", "+ Add Card")
             |> render_click()

      # Should show the card in edit mode with empty title placeholder
      assert has_element?(lv, "input[name='value']")
      assert has_element?(lv, "form[phx-submit='save_card_field']")

      # Submit the title form
      assert lv
             |> form("form[phx-submit='save_card_field']", %{
               value: "New Card"
             })
             |> render_submit()

      # Should display the new card with the entered title
      assert has_element?(lv, "h4", "New Card")
    end

    test "can cancel editing a new card", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Click add card button - creates card and enters edit mode
      assert lv
             |> element("button[phx-value-list-id='1']", "+ Add Card")
             |> render_click()

      assert has_element?(lv, "form[phx-submit='save_card_field']")

      # Press ESC to cancel editing
      assert lv |> element("input[name='value']") |> render_keyup(%{"key" => "Escape"})

      # Should exit edit mode and show the card with placeholder text
      refute has_element?(lv, "form[phx-submit='save_card_field']")
      assert has_element?(lv, "h4", "Enter card title...")
    end

    test "handles move_card event between predefined lists", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card using the LiveView
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()

      lv
      |> form("form[phx-submit='save_card_field']", %{value: "Movable Card"})
      |> render_submit()

      # Find the created card
      cards = Ash.read!(Card)
      card = Enum.find(cards, &(&1.title == "Movable Card"))
      assert card != nil

      # Simulate drag and drop event
      assert lv
             |> render_hook("move_card", %{
               card_id: card.id,
               from_list_id: "1",
               to_list_id: "2",
               new_position: 0
             })

      # Card should have moved to the new list
      updated_card = Ash.get!(Card, card.id)
      assert updated_card.list_id == 2
    end

    test "requires authentication", %{conn: conn} do
      # Test without authentication should redirect to login
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, "/board")
    end

    test "multiple clients receive real-time updates", %{conn: conn} do
      # Start two separate LiveView processes
      conn1 = authenticate_conn(conn)
      conn2 = authenticate_conn(Phoenix.ConnTest.build_conn())

      {:ok, lv1, _html1} = live(conn1, "/board")
      {:ok, lv2, _html2} = live(conn2, "/board")

      # Create a card on client 1
      lv1
      |> element("button[phx-value-list-id='1']", "+ Add Card")
      |> render_click()

      # Fill in the card title
      lv1
      |> form("form[phx-submit='save_card_field']", %{value: "Real-time Test Card"})
      |> render_submit()

      # Client 2 should automatically update to show the new card
      html2 = render(lv2)
      assert html2 =~ "Real-time Test Card"
    end

    test "can edit card titles by clicking", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card using the LiveView
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()

      lv
      |> form("form[phx-submit='save_card_field']", %{value: "Original Card"})
      |> render_submit()

      # Card should now be visible
      _html = render(lv)

      # Click to edit the card title
      lv
      |> element("h4", "Original Card")
      |> render_click()

      # Should show the edit form
      assert has_element?(lv, "input[value='Original Card']")

      # Submit the edit form
      lv
      |> form("form[phx-submit='save_card_field']", %{value: "Edited Card"})
      |> render_submit()

      # Should show the updated title
      assert has_element?(lv, "h4", "Edited Card")
      refute has_element?(lv, "h4", "Original Card")
    end

    test "can edit card descriptions by clicking", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card with description using the LiveView
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()
      lv |> form("form[phx-submit='save_card_field']", %{value: "Test Card"}) |> render_submit()

      # Add description by clicking the add description link and updating it
      lv |> element("p", "Add description...") |> render_click()

      lv
      |> form("form[phx-submit='save_card_field']", %{value: "Original description"})
      |> render_submit()

      # Card should now be visible with description
      _html = render(lv)

      # Click to edit the card description
      lv
      |> element("p", "Original description")
      |> render_click()

      # Should show the edit form with TextareaAutoSave hook
      # Note: In the real UI, this textarea will:
      # - Save automatically when it loses focus (blur)
      # - Save when user presses Ctrl+Enter
      # - Cancel only when user presses Escape
      assert has_element?(lv, "textarea")

      # Submit the edit form (simulates the JavaScript save behavior)
      lv
      |> form("form[phx-submit='save_card_field']", %{value: "Edited description"})
      |> render_submit()

      # Should show the updated description
      assert has_element?(lv, "p", "Edited description")
      refute has_element?(lv, "p", "Original description")
    end

    test "can add description to card without description", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card without description using the LiveView
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()
      lv |> form("form[phx-submit='save_card_field']", %{value: "Test Card"}) |> render_submit()

      # Card should now be visible
      _html = render(lv)

      # Click to add description
      lv
      |> element("p", "Add description...")
      |> render_click()

      # Should show the edit form
      assert has_element?(lv, "textarea")

      # Submit the edit form
      lv
      |> form("form[phx-submit='save_card_field']", %{value: "New description"})
      |> render_submit()

      # Should show the new description
      assert has_element?(lv, "p", "New description")
      refute has_element?(lv, "p", "Add description...")
    end

    test "drag and drop position handling - off by one regression test", %{conn: conn} do
      # This test reproduces the off-by-one error in card positioning during drag and drop.
      # The bug occurs when a card is moved within the same list or between lists,
      # where the SortableJS newIndex doesn't account for position rebalancing.
      # After a card is moved, it may appear one position below where it should be.

      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create multiple cards in the same list to test positioning
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()
      lv |> form("form[phx-submit='save_card_field']", %{value: "Card 1"}) |> render_submit()

      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()
      lv |> form("form[phx-submit='save_card_field']", %{value: "Card 2"}) |> render_submit()

      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()
      lv |> form("form[phx-submit='save_card_field']", %{value: "Card 3"}) |> render_submit()

      # Get all cards sorted by position
      all_cards =
        Card
        |> Ash.Query.sort(position: :asc)
        |> Ash.read!()

      cards = Enum.filter(all_cards, &(&1.list_id == 1))

      assert length(cards) == 3
      [card1, card2, card3] = cards
      assert card1.title == "Card 1"
      assert card2.title == "Card 2"
      assert card3.title == "Card 3"

      # Verify initial positions are sequential (floats with gaps)
      assert card1.position == 10.0
      assert card2.position == 20.0
      assert card3.position == 30.0

      # Move Card 3 to position 1 (between Card 1 and Card 2)
      # This simulates dragging Card 3 to the middle position
      lv
      |> render_hook("move_card", %{
        card_id: card3.id,
        from_list_id: "1",
        to_list_id: "1",
        new_position: 1
      })

      # Reload cards to check their new positions
      all_updated_cards =
        Card
        |> Ash.Query.sort(position: :asc)
        |> Ash.read!()

      updated_cards = Enum.filter(all_updated_cards, &(&1.list_id == 1))

      # After the move, the expected order should be:
      # Position 0: Card 1 (unchanged)
      # Position 1: Card 3 (moved here)
      # Position 2: Card 2 (shifted down)
      #
      # The bug would manifest as Card 3 appearing at position 2 instead of 1,
      # causing it to display one slot below where it should be

      card1_updated = Enum.find(updated_cards, &(&1.id == card1.id))
      card2_updated = Enum.find(updated_cards, &(&1.id == card2.id))
      card3_updated = Enum.find(updated_cards, &(&1.id == card3.id))

      # These assertions should pass after the fix
      assert card1_updated.position == 10.0, "Card 1 should remain at position 0.0"

      assert card3_updated.position == 15.0,
             "Card 3 should be at position 5.0 (moved between Card 1 and Card 2)"

      assert card2_updated.position == 20.0, "Card 2 should remain at position 10.0"

      # Verify the visual order matches the position order
      sorted_cards = Enum.sort_by(updated_cards, & &1.position)
      assert Enum.map(sorted_cards, & &1.title) == ["Card 1", "Card 3", "Card 2"]
    end

    test "displays finished and cancelled dropzones with proper accessibility attributes", %{
      conn: conn
    } do
      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/board")

      # Check that the finished dropzone exists with proper attributes
      assert html =~ "id=\"finished-dropzone\""
      assert html =~ "role=\"region\""
      assert html =~ "aria-label=\"Finished dropzone - Drop cards here to mark them as finished\""
      assert html =~ "aria-live=\"polite\""
      assert html =~ "aria-describedby=\"finished-help-text\""

      # Check that the cancelled dropzone exists with proper attributes
      assert html =~ "id=\"cancelled-dropzone\""
      assert html =~ "role=\"region\""

      assert html =~
               "aria-label=\"Cancelled dropzone - Drop cards here to mark them as cancelled\""

      assert html =~ "aria-live=\"polite\""
      assert html =~ "aria-describedby=\"cancelled-help-text\""

      # Check that the help text exists and is screen reader only
      assert html =~ "id=\"finished-help-text\""
      assert html =~ "id=\"cancelled-help-text\""
      assert html =~ "class=\"sr-only\""
      assert html =~ "Shift+F keyboard shortcut"
      assert html =~ "Shift+C keyboard shortcut"
    end

    test "can finish a card using finish_card event", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()
      lv |> form("form[phx-submit='save_card_field']", %{value: "Test Card"}) |> render_submit()

      # Get the created card
      cards = Ash.read!(Card)
      card = Enum.find(cards, &(&1.title == "Test Card"))
      assert card != nil
      # Should be in active lists
      assert card.list_id in [1, 2]

      # Finish the card using the finish_card event
      lv |> render_hook("finish_card", %{card_id: card.id})

      # Card should be finished and removed from the board
      updated_card = Ash.get!(Card, card.id)
      # Should be in finished list
      assert updated_card.list_id == 3
      assert updated_card.archived_at != nil

      # Card should no longer appear on the board
      html = render(lv)
      refute html =~ "Test Card"
    end

    test "can cancel a card using cancel_card event", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()
      lv |> form("form[phx-submit='save_card_field']", %{value: "Test Card"}) |> render_submit()

      # Get the created card
      cards = Ash.read!(Card)
      card = Enum.find(cards, &(&1.title == "Test Card"))
      assert card != nil
      # Should be in active lists
      assert card.list_id in [1, 2]

      # Cancel the card using the cancel_card event
      lv |> render_hook("cancel_card", %{card_id: card.id})

      # Card should be cancelled and removed from the board
      updated_card = Ash.get!(Card, card.id)
      # Should be in cancelled list
      assert updated_card.list_id == 4
      assert updated_card.archived_at != nil

      # Card should no longer appear on the board
      html = render(lv)
      refute html =~ "Test Card"
    end

    test "legacy archive_card event still works for backward compatibility", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()
      lv |> form("form[phx-submit='save_card_field']", %{value: "Test Card"}) |> render_submit()

      # Get the created card
      cards = Ash.read!(Card)
      card = Enum.find(cards, &(&1.title == "Test Card"))
      assert card != nil
      # Should be in active lists
      assert card.list_id in [1, 2]

      # Archive the card using the legacy archive_card event
      lv |> render_hook("archive_card", %{card_id: card.id})

      # Card should be finished (default behavior) and removed from the board
      updated_card = Ash.get!(Card, card.id)
      # Should be in finished list (legacy behavior)
      assert updated_card.list_id == 3
      assert updated_card.archived_at != nil

      # Card should no longer appear on the board
      html = render(lv)
      refute html =~ "Test Card"
    end

    test "archived cards are not visible on the board", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create and archive a card directly
      {:ok, card} = Ash.create(Card, %{title: "Archived Card", list_id: 1})

      {:ok, _archived_card} =
        card
        |> Ash.Changeset.for_update(:mark_finished)
        |> Ash.update()

      # Load the board - archived card should not be visible
      html = render(lv)
      refute html =~ "Archived Card"
    end

    test "finish_card event broadcasts to board and archive pages", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()

      lv
      |> form("form[phx-submit='save_card_field']", %{value: "Broadcast Test Card"})
      |> render_submit()

      # Get the created card
      cards = Ash.read!(Card)
      card = Enum.find(cards, &(&1.title == "Broadcast Test Card"))

      # Subscribe to both topics to verify broadcasts
      Phoenix.PubSub.subscribe(Hot.PubSub, "board:updates")
      Phoenix.PubSub.subscribe(Hot.PubSub, "archive:updates")

      # Finish the card
      lv |> render_hook("finish_card", %{card_id: card.id})

      # Should receive board update broadcast
      assert_receive {:board_updated, %{action: :card_finished, card: finished_card}}, 1000
      assert finished_card.id == card.id
      # Should be in finished list
      assert finished_card.list_id == 3

      # Should also receive archive page broadcast  
      assert_receive {:card_finished, finished_card}, 1000
      assert finished_card.id == card.id
      # Should be in finished list
      assert finished_card.list_id == 3
    end

    test "cancel_card event broadcasts to board and archive pages", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()

      lv
      |> form("form[phx-submit='save_card_field']", %{value: "Cancel Broadcast Test Card"})
      |> render_submit()

      # Get the created card
      cards = Ash.read!(Card)
      card = Enum.find(cards, &(&1.title == "Cancel Broadcast Test Card"))

      # Subscribe to both topics to verify broadcasts
      Phoenix.PubSub.subscribe(Hot.PubSub, "board:updates")
      Phoenix.PubSub.subscribe(Hot.PubSub, "archive:updates")

      # Cancel the card
      lv |> render_hook("cancel_card", %{card_id: card.id})

      # Should receive board update broadcast
      assert_receive {:board_updated, %{action: :card_cancelled, card: cancelled_card}}, 1000
      assert cancelled_card.id == card.id
      # Should be in cancelled list
      assert cancelled_card.list_id == 4

      # Should also receive archive page broadcast  
      assert_receive {:card_cancelled, cancelled_card}, 1000
      assert cancelled_card.id == card.id
      # Should be in cancelled list
      assert cancelled_card.list_id == 4
    end

    test "multiple clients see archive updates in real-time", %{conn: conn} do
      # Start two separate LiveView processes
      conn1 = authenticate_conn(conn)
      conn2 = authenticate_conn(Phoenix.ConnTest.build_conn())

      {:ok, lv1, _html1} = live(conn1, "/board")
      {:ok, lv2, _html2} = live(conn2, "/board")

      # Create a card on client 1
      lv1 |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()

      lv1
      |> form("form[phx-submit='save_card_field']", %{value: "Multi-Client Test"})
      |> render_submit()

      # Both clients should see the card
      html1 = render(lv1)
      html2 = render(lv2)
      assert html1 =~ "Multi-Client Test"
      assert html2 =~ "Multi-Client Test"

      # Get the created card
      cards = Ash.read!(Card)
      card = Enum.find(cards, &(&1.title == "Multi-Client Test"))

      # Finish the card on client 1
      lv1 |> render_hook("finish_card", %{card_id: card.id})

      # Both clients should no longer see the card
      html1_after = render(lv1)
      html2_after = render(lv2)
      refute html1_after =~ "Multi-Client Test"
      refute html2_after =~ "Multi-Client Test"
    end

    test "cards are focusable and have proper accessibility attributes", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Create a card
      lv |> element("button[phx-value-list-id='1']", "+ Add Card") |> render_click()

      # Submit the card form that appears after clicking add card
      lv
      |> form("form[phx-submit='save_card_field']", %{value: "Focusable Card"})
      |> render_submit()

      html = render(lv)

      # Check that cards have proper accessibility attributes
      assert html =~ "tabindex=\"0\""
      assert html =~ "role=\"button\""

      assert html =~
               "aria-label=\"Card: Focusable Card - Press Shift+F to finish, Shift+C to cancel, or Shift+Delete to archive\""

      assert html =~ "focus:outline-none focus:ring-2 focus:ring-blue-500"
    end

    test "dropzones start hidden and have proper styling", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/board")

      # Check that both dropzones start with hidden classes
      assert html =~ "opacity-0"
      assert html =~ "scale-75"
      assert html =~ "transition-all duration-200"
      assert html =~ "pointer-events-none"

      # Check finished dropzone styling
      assert html =~ "bottom-4 right-4"
      assert html =~ "border-green-400"
      assert html =~ "bg-green-50"
      assert html =~ "border-dashed"
      assert html =~ "rounded-lg"
      assert html =~ "z-50"
      assert html =~ "Finished"
      assert html =~ "text-green-600"

      # Check cancelled dropzone styling
      assert html =~ "bottom-4 left-4"
      assert html =~ "border-red-400"
      assert html =~ "bg-red-50"
      assert html =~ "Cancelled"
      assert html =~ "text-red-600"

      # Check responsive sizing
      assert html =~ "w-32 h-32 sm:w-40 sm:h-40 md:w-48 md:h-48"
    end

    test "error handling when finishing non-existent card", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Try to finish a card that doesn't exist
      lv |> render_hook("finish_card", %{card_id: "non-existent-id"})

      # LiveView should handle the error gracefully without crashing
      # The page should still be functional
      html = render(lv)
      assert html =~ "Board"
      assert html =~ "new"
      assert html =~ "watching"
    end

    test "error handling when cancelling non-existent card", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Try to cancel a card that doesn't exist
      lv |> render_hook("cancel_card", %{card_id: "non-existent-id"})

      # LiveView should handle the error gracefully without crashing
      # The page should still be functional
      html = render(lv)
      assert html =~ "Board"
      assert html =~ "new"
      assert html =~ "watching"
    end

    test "finish_card event handles malformed parameters", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Try with missing card_id
      lv |> render_hook("finish_card", %{})

      # Try with nil card_id
      lv |> render_hook("finish_card", %{card_id: nil})

      # Try with empty string card_id
      lv |> render_hook("finish_card", %{card_id: ""})

      # LiveView should handle all these gracefully
      html = render(lv)
      assert html =~ "Board"
      assert html =~ "new"
      assert html =~ "watching"
    end

    test "cancel_card event handles malformed parameters", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/board")

      # Try with missing card_id
      lv |> render_hook("cancel_card", %{})

      # Try with nil card_id
      lv |> render_hook("cancel_card", %{card_id: nil})

      # Try with empty string card_id
      lv |> render_hook("cancel_card", %{card_id: ""})

      # LiveView should handle all these gracefully
      html = render(lv)
      assert html =~ "Board"
      assert html =~ "new"
      assert html =~ "watching"
    end
  end
end
