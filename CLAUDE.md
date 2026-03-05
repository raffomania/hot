# CLAUDE.md - hot tv show tracking app

Hot is a home-cooked, small app for interacting with tv show tracking data.

## Development Commands

ALWAYS use `just` tasks to interact with the project (e.g. running tests, formatting, running the server) - if a needed just task doesn't exist, add a todo to `docs/todo.md`.

### Setup and Running
- `just run` - Install dependencies, migrate database, and start Phoenix server
- `just iex` - Start interactive Elixir shell with application loaded
- `just install-dependencies` - Install Elixir dependencies via mix

### Database Operations
- `just migrate-db` - Create and migrate SQLite database using Ash
- `just reset-db` - Drop and recreate database with migrations
- `just generate-migration <name>` - Generate new Ash migration with codegen

### Testing and Building
- `just test` - Run test suite (uses environment variables from .env)
- `just build-container` - Build container image with Podman
- `just run-container` - Build and run containerized version
- `just outdated` - Find outdated dependencies
- `just update-dependencies` - Update all dependencies
- `just clean` - Remove all build artifacts

### Development Environment
- Running in a docker container
- `just seed-db` - Populate database with seed data
- `just update-trakt` - Manually sync latest Trakt data (also runs automatically every 8h via `Hot.Trakt.Updater`)

## Architecture Overview
Core Framework Stack is Ash, Phoenix, SQLite with AshSqlite data layer. Styling is done using Tailwind.

### Domain Structure
The application uses Ash Domain pattern with `Hot.Trakt` as the primary domain containing:
- `Hot.Trakt.Show` - TV show resource with Trakt/IMDB integration
- `Hot.Trakt.Season` - Season resource linked to shows
- `Hot.Trakt.Episode` - Episode resource with watch tracking
- `Hot.Trakt.Card` - Kanban card resource; shows are tracked as cards in lists
- `Hot.Trakt.BoardLists` - Configuration module for predefined lists (new/watching/finished/cancelled)
- `Hot.Trakt.PositionManager` - Fractional positioning for cards with lazy rebalancing
- `Hot.Trakt.Updater` - GenServer that syncs Trakt data every 8 hours

### Board UI
The primary interface is a Kanban board (Phoenix LiveView) with two active lists ("new", "watching") and archive lists ("finished", "cancelled"). Cards support drag-and-drop reordering via SortableJS. Real-time multi-client sync uses Phoenix PubSub.

### External Integrations
- Trakt API Client (`Hot.Trakt.Api`) fetches user watch data

### Database Schema
- Shows have `trakt_id`, `imdb_id`, and `title` with unique constraints
- Seasons belong to shows with episode relationships
- Episodes track `last_watched_at` for user activity
- Cards have `list_id`, `position` (float for fractional ordering), optional `show_id`, and `archived_at`
- Uses Ash upsert patterns for data synchronization

### Configuration
- Trakt API credentials via application config

## Documentation

- docs/authentication.md - Authentication specification and implementation guide
- docs/design.md - Design guide for minimalistic UI approach
- docs/board.md - Kanban board technical documentation
- docs/prompt_plan.md - Planned prompts / implementation tasks

## Gleam Port

Hot is being incrementally ported to Gleam. Both projects coexist: Elixir on port 4000, Gleam on port 4001.

**Plan**: `docs/gleam-port.md` (10 phases)
**Current status**: Phases 0-4 complete (scaffolding, DB/CRUD, board page, card editing, drag-and-drop). Phase 5 next: Authentication.

### Gleam Stack
- Web: Wisp + Mist
- Database: sqlight (direct SQL, separate `gleam/hot_gleam_dev.db`)
- HTML: Lustre HTML builder
- Interactivity: HTMX
- Real-time: Mist SSE + gleam_otp actor
- Background tasks: gleam_otp actor
- Styling: Tailwind standalone CLI

### Gleam Development Commands
All Gleam commands run from `gleam/` subdirectory:
- `cd gleam && just run` - Start Gleam server on port 4001
- `cd gleam && just test` - Run Gleam test suite
- `cd gleam && just build` - Build Gleam project
- `cd gleam && just format` - Format Gleam code
- `cd gleam && just clean` - Remove build artifacts