# CLAUDE.md - hot tv show tracking app

Hot is a home-cooked, small app for interacting with tv show tracking data.

## Development Commands

### Setup and Running
- `just run` - Install dependencies, migrate database, and start Phoenix server
- `just iex` - Start interactive Elixir shell with application loaded
- `mix phx.server` - Start Phoenix server directly
- `just install-dependencies` - Install Elixir dependencies via mix

### Database Operations
- `just migrate-db` - Create and migrate SQLite database using Ash
- `just reset-db` - Drop and recreate database with migrations
- `just generate-migration <name>` - Generate new Ash migration with codegen

### Testing and Building
- `mix test` - Run test suite (includes ash.setup)
- `mix ash.setup --quiet` - Setup Ash resources for testing
- `just build-container` - Build container image with Podman
- `just run-container` - Build and run containerized version

### Asset Management
- `mix assets.setup` - Install Tailwind and esbuild if missing
- `mix assets.build` - Build assets for development
- `mix assets.deploy` - Build and minify assets for production

### Development Environment
- Running in a docker container

## Architecture Overview

### Core Framework Stack
- **Phoenix 1.7+** with LiveView for real-time UI
- **Ash Framework** for resource management, APIs, and data modeling
- **SQLite** with AshSqlite data layer and Ecto ORM
- **TailwindCSS** for styling with Heroicons integration

### Domain Structure
The application uses Ash Domain pattern with `Hot.Trakt` as the primary domain containing:
- `Hot.Trakt.Show` - TV show resource with Trakt/IMDB integration
- `Hot.Trakt.Season` - Season resource linked to shows
- `Hot.Trakt.Episode` - Episode resource with watch tracking

### Key Application Components
- **Application Supervisor** (`Hot.Application`) manages:
  - Phoenix endpoint and PubSub
  - Database repo and auto-migrations
  - Background Trakt updater GenServer
  - Finch HTTP client for external API calls

### Web Layer
- **Router** (`HotWeb.Router`) defines:
  - Main show browsing routes with LiveView
  - Admin interface at `/admin` (development only)
  - LiveDashboard at `/dev/dashboard` (development only)
- **LiveView Components** in `HotWeb.ShowLive.*` for interactive UI
- **Core Components** provide reusable UI elements

### External Integrations
- **Trakt API Client** (`Hot.Trakt.Api`) fetches user watch data
- **Admin Interface** via AshAdmin for data management

### Database Schema
- Shows have `trakt_id`, `imdb_id`, and `title` with unique constraints
- Seasons belong to shows with episode relationships
- Episodes track `last_watched_at` for user activity
- Uses Ash upsert patterns for data synchronization

### Configuration
- Environment-specific configs in `config/` directory
- Trakt API credentials via application config
- Auto-migration handling in production releases

## Documentation

- **docs/authentication.md** - Authentication specification and implementation guide
- **docs/design.md** - Design guide for minimalistic UI approach