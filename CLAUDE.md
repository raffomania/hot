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
- `just test` - Run test suite (uses environment variables from .env)
- `mix test` - Run test suite (includes ash.setup)
- `mix ash.setup --quiet` - Setup Ash resources for testing
- `just build-container` - Build container image with Podman
- `just run-container` - Build and run containerized version

### Development Environment
- Running in a docker container

## Architecture Overview
Core Framework Stack is Ash, Phoenix, SQLite with AshSqlite data layer. Styling is done using Tailwind.

### Domain Structure
The application uses Ash Domain pattern with `Hot.Trakt` as the primary domain containing:
- `Hot.Trakt.Show` - TV show resource with Trakt/IMDB integration
- `Hot.Trakt.Season` - Season resource linked to shows
- `Hot.Trakt.Episode` - Episode resource with watch tracking

### External Integrations
- Trakt API Client (`Hot.Trakt.Api`) fetches user watch data

### Database Schema
- Shows have `trakt_id`, `imdb_id`, and `title` with unique constraints
- Seasons belong to shows with episode relationships
- Episodes track `last_watched_at` for user activity
- Uses Ash upsert patterns for data synchronization

### Configuration
- Trakt API credentials via application config

## Documentation

- docs/authentication.md - Authentication specification and implementation guide
- docs/design.md - Design guide for minimalistic UI approach