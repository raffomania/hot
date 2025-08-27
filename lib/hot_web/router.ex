defmodule HotWeb.Router do
  use HotWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HotWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :protected do
    plug :browser
    plug HotWeb.SharedAuth
  end

  # Auth routes (public)
  scope "/auth", HotWeb do
    pipe_through :browser
    get "/login", AuthController, :login
    post "/login", AuthController, :authenticate
    delete "/logout", AuthController, :logout
  end

  # Public routes
  scope "/", HotWeb do
    pipe_through :browser
    get "/", PageController, :home
    live "/shows", ShowLive.Index, :index
    live "/shows/:id", ShowLive.Show, :show
  end

  # Protected routes
  scope "/", HotWeb do
    pipe_through :protected

    live_session :protected, on_mount: HotWeb.SharedAuth do
      live "/board", BoardLive.Index, :index
      live "/archive", ArchiveLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", HotWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:hot, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HotWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  if Application.compile_env(:hot, :dev_routes) do
    import AshAdmin.Router

    scope "/admin" do
      pipe_through :browser

      ash_admin "/"
    end
  end
end
