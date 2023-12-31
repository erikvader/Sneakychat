# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :sneaky,
  ecto_repos: [Sneaky.Repo]

# Configures the endpoint
config :sneaky, SneakyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "fPBw0x7PYkBKIwTsZh9/rqzVRll+nmC9kf8Y0Fe/pnY5NZeLxb5Bl1lFtnzAHxWS",
  render_errors: [view: SneakyWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Sneaky.PubSub, adapter: Phoenix.PubSub.PG2]

config :ueberauth, Ueberauth,
  providers: [
    identity: {Ueberauth.Strategy.Identity, [
      callback_methods: ["POST"], 
      request_path: "/auth",
      callback_path: "/auth/identity/callback"]}
  ]

config :sneaky, Sneaky.Guardian,
  issuer: "sneaky",
  secret_key: "nVjM7blp0Y/JNHqzUyHHD7yaD9DpVH2CYD5O0ZxogTszPU0GwNGqZjZV6VaYIg/l"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
