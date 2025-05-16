run:
    mix phx.server
    
build-container:
    podman build --tag=ghcr.io/raffomania/hot .

run-container: build-container
    podman run -e "SECRET_KEY_BASE=$(pwgen 64)" -e "PHX_HOST=localhost" -v "container-data:/data" -p 4000:4000 ghcr.io/raffomania/hot