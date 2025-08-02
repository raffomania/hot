ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Hot.Repo, :manual)

# Setup Ash resources for testing
Mix.Task.run("ash.setup", ["--quiet"])
