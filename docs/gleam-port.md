# Plan: Port Hot to Gleam (Incremental)

## Context

Hot is a TV show tracking kanban board built with Elixir/Phoenix/Ash/SQLite. We're porting it to Gleam incrementally, with both projects coexisting side-by-side so we can run and compare them. The Gleam version should be straightforward — replacing Elixir-specific libraries and patterns with idiomatic Gleam equivalents.

## Key Decisions

- **Location**: Subdirectory at `gleam/` inside the existing repo
- **UI**: Wisp + HTMX + Lustre (HTML builder only). May explore Lustre server components later for interactive pages like the board
- **Database**: Separate SQLite file (`gleam/hot_gleam_dev.db`), own schema creation
- **Port**: 4001 (Elixir stays on 4000)

## Gleam Stack

| Concern | Elixir | Gleam |
|---|---|---|
| Web framework | Phoenix | Wisp + Mist |
| Database | Ash + AshSqlite | sqlight (direct SQL) |
| HTML | HEEx templates | Lustre HTML builder |
| Interactivity | LiveView | HTMX |
| Real-time sync | Phoenix PubSub | Mist SSE + gleam_otp actor |
| Background tasks | GenServer | gleam_otp actor |
| HTTP client | Finch | gleam_httpc |
| JSON | Jason | gleam_json |
| Auth sessions | Phoenix sessions | Wisp signed cookies |
| Styling | Tailwind (mix dep) | Tailwind (standalone CLI) |
| Drag-and-drop | SortableJS + LiveView hooks | SortableJS + HTMX ajax |
| Testing | ExUnit | gleeunit |

## Phases

Each phase produces a working, testable milestone.

### Phase 0: Project Scaffolding
Create `gleam/` with dependencies, a Wisp server on port 4001 serving a static page, and a Justfile.

- `gleam.toml` — deps: wisp, mist, gleam_http, gleam_erlang, gleam_otp, gleam_json, lustre, sqlight, gleam_httpc, gleeunit
- `src/hot.gleam` — entry point, starts Mist
- `src/hot/router.gleam` — single route returning "Hello, Hot!"
- `src/hot/web.gleam` — middleware stack (logging, static files)
- `Justfile` — `run`, `test`, `build`
- **Verify**: `just run` → `http://localhost:4001` shows "Hello, Hot!"

### Phase 1: Database Schema + Card CRUD
SQLite schema matching the Elixir app. Card model with all queries. Position logic.

- `src/hot/database.gleam` — connection setup, `CREATE TABLE IF NOT EXISTS` for all 4 tables
- `src/hot/models/card.gleam` — Card type + SQL: create, get, list_active, list_finished, list_cancelled, update, delete, mark_finished, mark_cancelled, unarchive, move_to_position
- `src/hot/models/position.gleam` — fractional positioning: assign_end_position, calculate_move_position, rebalance_list
- `src/hot/models/board_lists.gleam` — hardcoded list config (1=new, 2=watching, 3=finished, 4=cancelled)
- `test/hot/card_test.gleam`, `test/hot/position_test.gleam`
- **Verify**: `just test` — all card CRUD and position tests pass

### Phase 2: Static Board Page
`GET /board` renders the kanban board with cards from the database. Read-only, no interactivity yet.

- `src/hot/pages/layout.gleam` — root HTML shell + app layout with nav bar
- `src/hot/pages/board.gleam` — queries active cards, renders two-column board
- `src/hot/pages/components.gleam` — shared card rendering
- Tailwind CSS: standalone CLI scanning `.gleam` files, output to `priv/static/css/app.css`
- **Verify**: `just run` → `/board` shows two columns with cards

### Phase 3: Board Interactivity (HTMX)
Full board CRUD via HTMX: add cards, inline edit, finish/cancel.

- Add HTMX + SortableJS to `priv/static/js/`
- HTMX endpoints returning HTML fragments:
  - `POST /board/cards` — create card
  - `PATCH /board/cards/:id` — update title/description
  - `GET /board/cards/:id/edit?field=title` — edit form fragment
  - `POST /board/cards/:id/finish` — archive as finished
  - `POST /board/cards/:id/cancel` — archive as cancelled
- `priv/static/js/app.js` — keyboard shortcuts (Shift+F, Shift+C), escape to cancel edit
- Detect `HX-Request` header to return fragment vs full page
- **Verify**: add a card, edit its title inline, finish it — all without full page reloads

### Phase 4: Drag-and-Drop
SortableJS triggers HTMX requests for card movement between lists.

- `POST /board/cards/:id/move` — accepts `to_list_id` + `target_index`, calculates fractional position
- SortableJS `onEnd` → `htmx.ajax("POST", ...)` with move data
- Finish/cancel dropzones (green/red) at bottom corners
- **Verify**: drag card from "new" to "watching", drag to finish dropzone, reload — positions persist

### Phase 5: Authentication
Shared password auth protecting `/board` and `/archive`.

- `src/hot/auth/shared_auth.gleam` — password validation (constant-time compare), signed cookie session
- `src/hot/pages/auth_page.gleam` — `GET /auth/login` (form), `POST /auth/login` (validate + set cookie), logout
- Auth middleware in `src/hot/web.gleam` — check cookie on protected routes, redirect to login
- `src/hot/config.gleam` — loads `SHARED_PASSWORD`, `TRAKT_API_KEY`, `TRAKT_USERNAME` from env
- **Verify**: `/board` without login → redirected to `/auth/login` → correct password → back to `/board`

### Phase 6: Archive Page
`GET /archive` shows finished/cancelled cards with restore.

- `src/hot/pages/archive.gleam` — two sections (finished green, cancelled red), restore button
- `POST /archive/cards/:id/restore` — unarchive card via HTMX
- **Verify**: finish a card on board → see it on archive → restore it → back on board

### Phase 7: Real-Time Multi-Client Sync (SSE)
When one client modifies the board, others see the update.

- `src/hot/events/broadcast.gleam` — gleam_otp actor maintaining list of SSE client subjects
- `src/hot/events/sse.gleam` — `GET /events/board` SSE endpoint via Mist
- Board page: `hx-sse="connect:/events/board"` + `hx-trigger="sse:board_updated"` refreshes board content
- All card-mutating endpoints broadcast after success
- **Verify**: two browser tabs on `/board`, add card in tab 1 → appears in tab 2

### Phase 8: Shows & Watch Log Pages
Public pages for viewing shows and episode watch history.

- `src/hot/models/show.gleam` — Show type, SQL queries, recent_shows_by_year
- `src/hot/models/episode.gleam` — Episode type, list_recent with joins
- `src/hot/pages/shows.gleam` — `GET /shows` recent episodes + shows grouped by year
- `src/hot/pages/show_detail.gleam` — `GET /shows/:id` show details
- `GET /` redirects to `/shows`
- **Verify**: `/shows` displays show data, click through to detail pages

### Phase 9: Trakt API Integration + Background Sync
Fetch watched shows from Trakt API, upsert into DB, auto-sync every 8h.

- `src/hot/trakt/api.gleam` — HTTP GET to Trakt API, JSON decoding, upsert with `INSERT OR REPLACE`
- `src/hot/trakt/updater.gleam` — gleam_otp actor, schedules sync every 8 hours
- `src/hot/models/show.gleam` + `season.gleam` + `episode.gleam` — upsert functions
- Add updater to supervision tree in `src/hot.gleam`
- `just update-trakt` for manual sync
- **Verify**: `just update-trakt` populates shows/seasons/episodes tables

### Phase 10: Polish & Containerization
Production readiness.

- Error pages (404, 500)
- Flash messages for auth
- URL linkification in card descriptions
- Seed data script
- `Containerfile` for production build
- Comprehensive test coverage
- `CLAUDE.md` for the Gleam project
- **Verify**: full test suite passes, container builds and runs

## Project Structure

```
gleam/
  gleam.toml
  Justfile
  CLAUDE.md
  .env
  src/
    hot.gleam
    hot/
      router.gleam
      web.gleam
      config.gleam
      database.gleam
      models/
        card.gleam
        show.gleam
        season.gleam
        episode.gleam
        board_lists.gleam
        position.gleam
      trakt/
        api.gleam
        updater.gleam
      auth/
        shared_auth.gleam
      pages/
        layout.gleam
        board.gleam
        archive.gleam
        shows.gleam
        show_detail.gleam
        auth_page.gleam
        components.gleam
      events/
        broadcast.gleam
        sse.gleam
  test/
    hot/
      card_test.gleam
      position_test.gleam
      auth_test.gleam
  priv/
    static/
      css/app.css
      js/
        app.js
        vendor/
          sortable.min.js
          htmx.min.js
```

## What Changes from Elixir and Why

- **No Ash Framework** → explicit SQL queries with sqlight. More verbose but transparent.
- **No LiveView** → HTMX for interactivity. Standard HTTP requests instead of persistent WebSocket. Simpler to reason about.
- **No HEEx** → Lustre HTML builder functions. Type-safe HTML in pure Gleam.
- **No Phoenix PubSub** → gleam_otp actor + Mist SSE. Same result, different mechanism.
- **No GenServer** → gleam_otp actor. Direct typed equivalent.
- **No Ecto changesets** → plain Gleam validation functions.
- **No Phoenix sessions** → Wisp signed cookies.

If HTMX feels limiting for the board (especially drag-and-drop + real-time), we can evaluate migrating the board page to a Lustre server component while keeping other pages as HTMX.
