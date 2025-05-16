defmodule Hot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HotWeb.Telemetry,
      Hot.Repo,
      {Ecto.Migrator, repos: Application.fetch_env!(:hot, :ecto_repos), skip: skip_migrations?()},
      {Phoenix.PubSub, name: Hot.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Hot.Finch},
      # Start a worker by calling: Hot.Worker.start_link(arg)
      # {Hot.Worker, arg},
      # Start to serve requests, typically the last entry
      HotWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HotWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
