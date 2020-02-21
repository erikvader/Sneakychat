defmodule Sneaky.Auth.Follow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "follows" do
    belongs_to :alice, Sneaky.Auth.Account
    belongs_to :bob, Sneaky.Auth.Account

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    # |> cast(attrs, [:alice, :bob])
    |> validate_required([:alice, :bob])
    |> unique_constraint(:follows_alice_bob_constaint, name: :follows_alice_bob)
  end

end
