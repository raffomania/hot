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
  end
end
