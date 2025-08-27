# Board Implementation: Technical Documentation

This document provides technical documentation for the Kanban-style board feature in the Hot TV show tracking application.

## Architecture Overview

The board is a real-time collaborative interface for organizing TV shows and tasks into predefined lists and cards using Phoenix LiveView and Ash Framework. The board uses a fixed set of two lists: "new" and "watching".

### Technology Stack

- **Backend**: Ash Framework with SQLite via AshSqlite data layer
- **Frontend**: Phoenix LiveView with Tailwind CSS styling
- **Real-time**: Phoenix PubSub for multi-client synchronization
- **Drag & Drop**: Vendored SortableJS library for card/list movement
- **Authentication**: Session-based protection via SharedAuth

## Data Model

### Domain Resources

The board implements two primary Ash resources within the `Hot.Trakt` domain:

**List Resource** (`lib/hot/trakt/list.ex`):
- UUID v7 primary key with position-based ordering
- Unique title constraint for list identification
- One-to-many relationship with cards
- Timestamps for audit tracking
- Two predefined lists: "new" (position 0), "watching" (position 1)

**Card Resource** (`lib/hot/trakt/card.ex`):
- UUID v7 primary key with position-based ordering within lists
- Required title and optional description fields
- Foreign key relationships to lists (required) and shows (optional)
- Support for TV show integration via existing Show resource

### Database Schema

Tables use standard Ash conventions with `id`, `inserted_at`, and `updated_at` fields. The lists table stores title and position, while cards include title, description, position, list_id, and optional show_id references.

## LiveView Implementation

### Core Controller (`lib/hot_web/board_live/index.ex`)

The main LiveView manages board state through several key areas:

**State Management**: Socket assigns track editing states, modal visibility, and data collections. PubSub subscription enables real-time updates when socket connects. The mount function ensures default lists exist via `ensure_default_lists/1`.

**Event Handling**: Implements handlers for card CRUD operations, drag-and-drop movement, and inline editing workflows. List management is removed since lists are predefined.

**Data Loading**: The `load_board_data/1` function efficiently queries lists and cards with position sorting and show preloading for display.

### Real-time Collaboration

All board operations broadcast to the `"board:updates"` PubSub topic with structured messages containing action types and affected resources. Connected clients receive updates via `handle_info/2` and automatically refresh their data.

## JavaScript Integration

### Drag-and-Drop System (`assets/js/app.js`)

Three specialized hooks manage interactive behavior:

**Board Hook**: Handles horizontal list reordering with SortableJS group configuration and position tracking via `move_list` events.

**BoardList Hook**: Manages vertical card movement within and between lists using shared card groups, extracting list IDs from DOM data attributes.

**TextareaAutoSave Hook**: Provides enhanced textarea editing with auto-save on blur and manual save via Ctrl+Enter, addressing user experience requirements for description editing.

SortableJS is vendored at `assets/vendor/sortable.min.js` to avoid npm dependencies per project requirements.

## User Interface Features

### Inline Editing System

**List Titles**: Lists have fixed titles and are not editable since they represent predefined categories.

**Card Content**: Separate editing modes for titles (input fields) and descriptions (textarea with auto-save). Cards without descriptions show "Add description..." prompts.

**Focus Management**: Custom hooks ensure input fields receive focus and text selection for optimal user experience.

### Modal Workflows

Modal forms handle card creation with proper focus management, validation, and cancellation options. Modals support click-away, Cancel buttons, and Escape key dismissal. List creation is removed since lists are predefined.

### Responsive Layout

The board uses CSS flexbox with horizontal scrolling for desktop/tablet compatibility. Lists maintain fixed widths (min/max 80 units) while cards stack vertically within their containers.

## Testing Strategy

### Test Coverage (50 tests, 1 skipped)

**Resource Tests** (`test/hot/trakt/{list,card}_test.exs`):
Tests validate CRUD operations for cards, constraint enforcement, relationship integrity, and position-based sorting functionality. List tests focus on the predefined structure.

**LiveView Tests** (`test/hot_web/board_live/index_test.exs`):
Comprehensive integration testing covers board rendering, form workflows, inline editing, drag-and-drop simulation, authentication protection, and multi-client real-time updates.

**Key Integration Test**: Multi-client collaboration is verified by creating separate LiveView processes and confirming that changes made in one client automatically appear in another via PubSub.

## Security & Performance

### Security Measures

Route protection requires authentication through `HotWeb.SharedAuth` with session-based verification. The board LiveView runs within a protected live_session that validates user authentication before access.

### Performance Optimizations

Database queries use efficient position-based sorting via `Ash.Query.sort(position: :asc)`. PubSub updates trigger minimal data reloads rather than full page refreshes. Position management uses simple integer ordering for fast resequencing operations.

## Implementation Status

### Current Capabilities

- Predefined list structure: new, watching
- Full CRUD operations for cards within predefined lists
- Real-time multi-client collaboration
- Drag and drop card movement between lists
- Inline editing with enhanced UX for card descriptions
- Comprehensive test coverage with integration scenarios
- Authentication and route protection

## Position Management System

### Ash-Native Position Management

The board uses an integrated Ash-native position management system that leverages Ash's resource changes and custom actions for automatic position handling:

#### Core Architecture
- **Ash Changes**: Position logic integrated directly into resource actions via custom changes
- **Automatic Positioning**: New cards automatically assigned to end of lists (10.0, 20.0, 30.0...)  
- **Fractional Moves**: Moving cards uses fractional positioning between existing positions
- **Transparent Integration**: Position management works through standard Ash actions

#### Implementation Components

**AssignPosition Change** (`Hot.Trakt.Changes.AssignPosition`):
```elixir
# Automatically assigns positions to new cards
def change(changeset, _opts, _context) do
  list_title = Ash.Changeset.get_attribute(changeset, :list_title)
  new_position = calculate_end_position(list_title)  # last_position + 10.0
  Ash.Changeset.change_attribute(changeset, :position, new_position)
end
```

**MoveToPosition Change** (`Hot.Trakt.Changes.MoveToPosition`):
```elixir
# Handles card moves with fractional positioning
card
|> Ash.Changeset.for_update(:move_to_position, %{
  new_list_title: "watching", 
  target_index: 1
})
|> Ash.update()
```

**Custom Actions in Card Resource**:
```elixir
create :create do
  change Hot.Trakt.Changes.AssignPosition  # Auto-position new cards
end

update :move_to_position do
  argument :new_list_title, :string
  argument :target_index, :integer
  change Hot.Trakt.Changes.MoveToPosition  # Handle complex moves
end
```

#### Benefits of Ash-Native Approach
- **Integrated Architecture**: Position logic lives within Ash resources, not external modules
- **Declarative**: Position management expressed through Ash's change system
- **Automatic**: New cards positioned automatically without manual calculation
- **Maintainable**: Leverages Ash's native patterns and conventions
- **Transparent**: Standard Ash CRUD operations handle position management internally

#### Position Strategy
- **New Cards**: Always added to end of list with 10.0 increment (10.0, 20.0, 30.0...)
- **Card Moves**: Use fractional positioning between existing cards (insert at 15.0 between 10.0 and 20.0)
- **Rebalancing**: Automatic rebalancing when positions get too close (< 0.001 gap)
- **Single Operations**: Most moves require only one database update

## TODO

When finished with a todo, remove it. Make sure all tests pass on finishing. Update the docs in this file, if necessary.

- Create a new Ash Domain for board-related resources: Call it `Board`. Move Board Lists, Cards, card changes, and the position manager into it.
- Add a drop area for deleting cards to the right of all lists.