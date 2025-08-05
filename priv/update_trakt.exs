#!/usr/bin/env elixir

# Script to run the Hot.Trakt.Updater update function once
# Usage: mix run priv/update_trakt.exs

IO.puts("Starting Trakt update...")

try do
  Hot.Trakt.Updater.update()
  IO.puts("Trakt update completed successfully!")
rescue
  error ->
    IO.puts("Error during Trakt update: #{inspect(error)}")
    System.halt(1)
end
