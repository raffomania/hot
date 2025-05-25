set dotenv-load := true

run: migrate-db
    mix phx.server

iex:
    iex -S mix

migrate-db:
    mix ash_sqlite.create
    mix ash_sqlite.migrate

reset-db: && migrate-db
    mix ash_sqlite.drop
    
build-container:
    podman build --tag=ghcr.io/raffomania/hot .

run-container: build-container
    podman run -e "SECRET_KEY_BASE=$(pwgen 64)" -e "PHX_HOST=localhost" -v "container-data:/data" -p 4000:4000 ghcr.io/raffomania/hot

generate-migration name:
    mix ash.codegen --name {{name}}