defmodule SneakyWeb.Router do
  use SneakyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SneakyWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", SneakyWeb.API do
    pipe_through :api

    scope "/auth" do
      # post "/identity", AuthController, :request
      post "/identity/callback", AuthController, :identity_callback
      post "/identity/register", AuthController, :identity_register
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", SneakyWeb do
  #   pipe_through :api
  # end
end
