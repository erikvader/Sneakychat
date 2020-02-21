defmodule Sneaky.Auth.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string
    belongs_to :account, Sneaky.Auth.Account

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password, :account])
    |> unique_constraint(:email)
    |> unique_constraint(:account)
  end

end
