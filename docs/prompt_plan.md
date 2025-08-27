# Prompt Plan: Board Layout Changes and Archive Feature

This document contains the prompt plan for modifying the board layout and adding archive functionality to the Hot TV show tracking application.

## Overview

Transform the current four-column board layout ("trailers", "watching", "cancelled", "finished") into a simplified two-column layout ("new", "watching") with archive functionality for removed cards.

## 1. Modify Board Columns to "new" and "watching" ✅ **COMPLETED**

**Status:** ✅ **COMPLETED**

**Implementation Summary:**
- Updated `Hot.Trakt.BoardLists` to define only two lists: "new" (position 0, list_id 1) and "watching" (position 1, list_id 2)
- Updated `priv/repo/seeds.exs` to create sample cards across the two lists instead of four
- Updated tests in `test/hot_web/board_live/index_test.exs` to expect the new list names
- Updated documentation in `docs/board.md` to reflect the new two-column structure
- All existing functionality works with the simplified layout
- All board and card tests pass (19 tests, 0 failures)

## 2. Modify Card Model to Add Archive Status

**Prompt:**
```
Add archive functionality to the Card resource model in the Hot.Trakt domain. The changes needed are:

1. Add an `archived` boolean field to the Card resource (default: false)
2. Add an `archived_at` timestamp field to track when cards were archived
3. Create a custom Ash action `:archive` that sets archived=true and archived_at=current_timestamp
4. Create a custom Ash action `:unarchive` that sets archived=false and archived_at=nil
5. Update the default queries to exclude archived cards from the main board view
6. Create a separate query to fetch only archived cards for the archive page
7. Generate and run the database migration for the new fields
8. Update the Card resource tests to cover the new archive functionality

Ensure archived cards are completely hidden from the main board but can be retrieved separately for the archive view.
```

## 3. Create Archive Page

**Prompt:**
```
Create a dedicated archive page to display archived cards. This should include:

1. Create a new LiveView at `lib/hot_web/archive_live/index.ex` that displays archived cards
2. Add a route `/archive` in the router that requires authentication
3. Design the archive page layout to show archived cards in a simple list or grid format
4. Include the card title, description, archived date, and any associated show information
5. Add functionality to unarchive cards (move them back to the "new" column on the main board)
6. Add a navigation link in the main app layout/header to access the archive
7. Use similar styling to the main board but optimized for viewing archived content
8. Add real-time updates via PubSub when cards are archived/unarchived from the main board
9. Include a "Back to Board" navigation link
10. Write comprehensive tests for the archive LiveView functionality

The archive should provide a clean, organized view of historical cards with easy restoration capabilities.
```

## 4. Add Archive Dropzone on Board Page

**Prompt:**
```
Add an archive dropzone to the main board page that allows users to archive cards by dragging them. The implementation should include:

1. Create a visual dropzone that appears in the lower right corner of the screen when a user starts dragging a card
2. Style the dropzone with appropriate visual feedback (e.g., archive icon, "Archive" text, hover states)
3. Integrate with the existing SortableJS drag-and-drop system to detect when cards are dropped on the archive zone
4. Add JavaScript hooks to handle the archive dropzone interaction:
   - Show dropzone only when dragging starts
   - Hide dropzone when dragging ends
   - Handle drop events on the archive zone
5. Send a LiveView event to archive the card when dropped on the archive zone
6. Provide visual feedback during the archive process (loading state, success animation)
7. Update the board immediately after archiving (remove card from view)
8. Broadcast the archive action via PubSub for real-time updates to other clients
9. Ensure the dropzone doesn't interfere with existing list-to-list card movement
10. Add accessibility features (keyboard shortcuts, screen reader support)
11. Write tests to verify the archive dropzone functionality

The dropzone should feel intuitive and provide clear visual feedback throughout the interaction.
```

## Technical Considerations

- Maintain existing Ash Framework architecture and patterns
- Preserve Phoenix LiveView real-time functionality
- Keep comprehensive test coverage
- Follow the project's existing code conventions
- Ensure all changes integrate with the current authentication system
- Maintain the vendored SortableJS drag-and-drop implementation