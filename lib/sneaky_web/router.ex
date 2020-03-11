defmodule SneakyWeb.Router do
  use SneakyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :maybe_auth do
    plug Guardian.Plug.Pipeline, module: Sneaky.Guardian
    plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
    plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  end

  pipeline :just_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :load_auth do
    plug Guardian.Plug.LoadResource, allow_blank: true
  end

  pipeline :check_admin do
    
  end

  pipeline :check_moderator do

  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SneakyWeb do
    pipe_through :browser

    get "/", PageController, :index

    get "/auth", AuthController, :request
    post "/auth/identity/callback", AuthController, :identity_callback

    scope "/admin" do
      pipe_through [:maybe_auth, :just_auth]

      get "/", AdminController, :index
      
      scope "/account" do
        get "/", AdminController, :account
        get "/list", AdminController, :account_list
      end

      #! TODO: Should not require authentication
      #! TODO: Check if already set-up
      scope "/setup" do
        get "/", AdminController, :setup
        post "/", AdminController, :setup
        get "/step/:step", AdminController, :setup
      end
    end
  end

  scope "/api", SneakyWeb.API do
    pipe_through :api

    scope "/auth" do
      # post "/identity", AuthController, :request
      post "/identity/callback", AuthController, :identity_callback
      post "/identity/register", AuthController, :identity_register
    end
  end

  scope "/users", SneakyWeb do
    pipe_through :api

    post "/:username/inbox", InboxController, :inbox
  end

  get "/sneakies/:imgpath", SneakyWeb.SneakController, :get

  # Other scopes may use custom stacks.
  # scope "/api", SneakyWeb do
  #   pipe_through :api
  # end
end
