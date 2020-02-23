defmodule Sneaky.Auth.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :username, :string
    field :url, :string
    has_one :user, Sneaky.Auth.User

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :url])
    |> validate_required([:username, :url])
    |> unique_constraint(:accounts_username_url_constraint, name: :accounts_username_url)
  end

end
