set dotenv-load := true

# Start the development server
run: install-dependencies migrate-db
    mix phx.server

# Start an interactive elixir shell
iex: install-dependencies
    iex -S mix

install-dependencies:
    mix deps.get

# Create the database if it doesn't exist, then run all migrations that are not yet applied
migrate-db:
    mix ash_sqlite.create
    mix ash_sqlite.migrate

# Drop the database if it exists, then create & migrate a new one
reset-db: && migrate-db
    mix ash_sqlite.drop
    
# Build a container containing a release for production
build-container: install-dependencies
    podman build --tag=ghcr.io/raffomania/hot .

# Run the production container. Useful for testing the Containerfile
run-container: build-container
    podman run -e "SECRET_KEY_BASE=$(pwgen 64)" -e "PHX_HOST=localhost" -v "container-data:/data" -p 4000:4000 ghcr.io/raffomania/hot

# Auto-generate a new migration with the given name
generate-migration name:
    mix ash.codegen --name {{name}}

# Remove all build artifacts
clean:
    mix clean
    rm -rf .elixir_ls
    rm -rf _build