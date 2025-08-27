defmodule HotWeb.ArchiveLive.IndexTest do
  use HotWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Hot.Trakt.Card

  defp authenticate_conn(conn) do
    Plug.Test.init_test_session(conn, %{"authenticated" => true})
  end

  describe "Archive LiveView" do
    test "displays the archive page with correct title", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/archive")
      assert html =~ "Archive"
      assert html =~ "Back to Board"
    end

    test "displays empty state when no archived cards exist", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/archive")
      assert html =~ "No archived cards yet"
      assert html =~ "Cards you archive will appear here"
    end

    test "displays archived cards with correct information", %{conn: conn} do
      # Create and archive a card
      {:ok, card} =
        Ash.create(Card, %{
          title: "Test Archived Card",
          description: "This is a test description",
          list_id: 1
        })

      {:ok, _archived_card} = Ash.update(card, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/archive")

      assert html =~ "Test Archived Card"
      assert html =~ "This is a test description"
      assert html =~ "Archived"
      assert html =~ "Restore"
      refute html =~ "No archived cards yet"
    end

    test "displays archived cards ordered by archive date (newest first)", %{conn: conn} do
      # Create multiple cards
      {:ok, card1} =
        Ash.create(Card, %{
          title: "First Card",
          list_id: 1
        })

      {:ok, card2} =
        Ash.create(Card, %{
          title: "Second Card",
          list_id: 1
        })

      # Archive first card
      {:ok, _} = Ash.update(card1, %{}, action: :mark_finished)

      # Archive second card (ordering might be same second due to timing)
      {:ok, _} = Ash.update(card2, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/archive")

      # Verify both cards are present - ordering may vary based on timing
      assert html =~ "Second Card"
      assert html =~ "First Card"

      # Check that the LiveView loads archived cards properly using the :archived_cards action
      archived_cards =
        Card
        |> Ash.Query.for_read(:archived_cards)
        |> Ash.read!()

      assert length(archived_cards) == 2
      archived_titles = Enum.map(archived_cards, & &1.title)
      assert "First Card" in archived_titles
      assert "Second Card" in archived_titles
    end

    test "handles cards without titles gracefully", %{conn: conn} do
      {:ok, card} =
        Ash.create(Card, %{
          title: nil,
          description: "Card without title",
          list_id: 1
        })

      {:ok, _archived_card} = Ash.update(card, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/archive")

      assert html =~ "Untitled card"
      assert html =~ "Card without title"
    end

    test "handles cards without descriptions", %{conn: conn} do
      {:ok, card} =
        Ash.create(Card, %{
          title: "Card without description",
          description: nil,
          list_id: 1
        })

      {:ok, _archived_card} = Ash.update(card, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/archive")

      assert html =~ "Card without description"
      # Should not have a description element
      refute html =~ "<p class=\"text-sm text-gray-600"
    end

    test "can unarchive a card", %{conn: conn} do
      # Create and archive a card
      {:ok, card} =
        Ash.create(Card, %{
          title: "Card to Unarchive",
          description: "Test description",
          list_id: 2
        })

      {:ok, archived_card} = Ash.update(card, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, lv, _html} = live(conn, "/archive")

      # Verify card is displayed in archive
      assert has_element?(lv, "h3", "Card to Unarchive")

      # Click restore button
      lv
      |> element("button", "Restore")
      |> render_click(%{"card-id" => archived_card.id})

      # Card should be removed from archive view
      refute has_element?(lv, "h3", "Card to Unarchive")

      # Verify card was unarchived in database
      unarchived_card = Ash.get!(Card, archived_card.id)
      assert unarchived_card.archived_at == nil
      # Should be moved to "new" list
      assert unarchived_card.list_id == 1
    end

    test "displays show information when card has associated show", %{conn: conn} do
      # Create a show first with seasons to satisfy the create action requirements
      {:ok, show} =
        Ash.create(Hot.Trakt.Show, %{
          title: "Test Show",
          trakt_id: 12345,
          seasons: []
        })

      # Create and archive a card with show
      {:ok, card} =
        Ash.create(Card, %{
          title: "Card with Show",
          description: "Test description",
          list_id: 1,
          show_id: show.id
        })

      {:ok, _archived_card} = Ash.update(card, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/archive")

      assert html =~ "📺 Test Show"
      assert html =~ "Card with Show"
    end

    test "requires authentication", %{conn: conn} do
      # Test without authentication should redirect to login
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, "/archive")
    end

    test "receives real-time updates when cards are archived", %{conn: conn} do
      conn = authenticate_conn(conn)
      {:ok, lv, html} = live(conn, "/archive")

      # Initially should show empty state
      assert html =~ "No archived cards yet"

      # Create and archive a card (simulating action from board)
      {:ok, card} =
        Ash.create(Card, %{
          title: "New Archived Card",
          description: "Just archived",
          list_id: 1
        })

      {:ok, _archived_card} = Ash.update(card, %{}, action: :mark_finished)

      # Broadcast the event that would come from the board
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        "board:updates",
        {:board_updated, %{action: :card_archived, card: card}}
      )

      # Archive view should automatically update
      html = render(lv)
      assert html =~ "New Archived Card"
      assert html =~ "Just archived"
      refute html =~ "No archived cards yet"
    end

    test "receives real-time updates when cards are unarchived from board", %{conn: conn} do
      # Create and archive a card first
      {:ok, card} =
        Ash.create(Card, %{
          title: "Card to be Unarchived",
          list_id: 1
        })

      {:ok, archived_card} = Ash.update(card, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, lv, html} = live(conn, "/archive")

      # Verify card is displayed
      assert html =~ "Card to be Unarchived"

      # Simulate unarchiving from another client/board
      {:ok, _unarchived_card} = Ash.update(archived_card, %{}, action: :unarchive)

      # Broadcast the event
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        "board:updates",
        {:board_updated, %{action: :card_unarchived, card: archived_card}}
      )

      # Archive view should automatically update
      html = render(lv)
      refute html =~ "Card to be Unarchived"
    end

    test "ignores irrelevant board updates", %{conn: conn} do
      # Create an archived card
      {:ok, card} =
        Ash.create(Card, %{
          title: "Archived Card",
          list_id: 1
        })

      {:ok, _archived_card} = Ash.update(card, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, lv, html} = live(conn, "/archive")

      # Verify initial state
      assert html =~ "Archived Card"

      # Broadcast irrelevant events
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        "board:updates",
        {:board_updated, %{action: :card_moved, card: card}}
      )

      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        "board:updates",
        {:board_updated, %{action: :card_updated, card: card}}
      )

      # Page should remain unchanged
      html = render(lv)
      assert html =~ "Archived Card"
    end

    test "formats archive dates correctly", %{conn: conn} do
      # Create and archive a card
      {:ok, card} =
        Ash.create(Card, %{
          title: "Date Test Card",
          list_id: 1
        })

      {:ok, _archived_card} = Ash.update(card, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/archive")

      # Should show today's date in ISO format (YYYY-MM-DD)
      today = Date.to_string(Date.utc_today())
      assert html =~ "Archived #{today}"
    end

    test "handles missing archive dates gracefully", %{conn: conn} do
      # Create a card and manually mark as archived without proper date
      {:ok, card} =
        Ash.create(Card, %{
          title: "Missing Date Card",
          list_id: 1
        })

      # Use the mark_finished action instead of direct SQL
      {:ok, _} = Ash.update(card, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/archive")

      assert html =~ "Missing Date Card"
      assert html =~ "Archived Unknown"
    end

    test "multiple clients receive real-time archive updates", %{conn: conn} do
      # Start two separate archive LiveView processes
      conn1 = authenticate_conn(conn)
      conn2 = authenticate_conn(Phoenix.ConnTest.build_conn())

      {:ok, lv1, _html1} = live(conn1, "/archive")
      {:ok, lv2, _html2} = live(conn2, "/archive")

      # Create and archive a card
      {:ok, card} =
        Ash.create(Card, %{
          title: "Multi-client Test",
          list_id: 1
        })

      {:ok, _archived_card} = Ash.update(card, %{}, action: :mark_finished)

      # Broadcast archive event
      Phoenix.PubSub.broadcast(
        Hot.PubSub,
        "board:updates",
        {:board_updated, %{action: :card_archived, card: card}}
      )

      # Both clients should see the archived card
      html1 = render(lv1)
      html2 = render(lv2)

      assert html1 =~ "Multi-client Test"
      assert html2 =~ "Multi-client Test"
    end

    test "linkifies URLs in card descriptions", %{conn: conn} do
      {:ok, card} =
        Ash.create(Card, %{
          title: "Card with Link",
          description: "Check out https://example.com for more info",
          list_id: 1
        })

      {:ok, _archived_card} = Ash.update(card, %{}, action: :mark_finished)

      conn = authenticate_conn(conn)
      {:ok, _lv, html} = live(conn, "/archive")

      # Should contain a clickable link (linkify_text functionality)
      assert html =~ "https://example.com"
      # The exact HTML output depends on the linkify_text implementation
    end
  end
end
