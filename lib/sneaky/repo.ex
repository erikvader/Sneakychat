defmodule Sneaky.Repo do
  use Ecto.Repo,
    otp_app: :sneaky,
    adapter: Ecto.Adapters.Postgres
end
