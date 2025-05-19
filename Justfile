set dotenv-load := true

run: migrate-db
    mix phx.server

iex:
    iex -S mix

migrate-db:
    mix ash_sqlite.create
    mix ash_sqlite.migrate

reset-db:
    mix ash_sqlite.drop
    
build-container:
    podman build --tag=ghcr.io/raffomania/hot .

run-container: build-container
    podman run -e "SECRET_KEY_BASE=$(pwgen 64)" -e "PHX_HOST=localhost" -v "container-data:/data" -p 4000:4000 ghcr.io/raffomania/hot

generate-migration name:
    mix ash.codegen --name {{name}}

regenerate-migrations name:
    #!/bin/bash

    # Get count of untracked migrations
    N_MIGRATIONS=$(git ls-files --others priv/repo/migrations | wc -l)

    # Rollback untracked migrations
    mix ash_sqlite.rollback -n $N_MIGRATIONS

    # Delete untracked migrations and snapshots
    git ls-files --others priv/repo/migrations | xargs rm
    git ls-files --others priv/resource_snapshots | xargs rm

    # Regenerate migrations
    mix ash.codegen --name {{name}}