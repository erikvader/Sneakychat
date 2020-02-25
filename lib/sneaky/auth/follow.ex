defmodule Sneaky.Auth.Follow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "follows" do
    belongs_to :subject, Sneaky.Auth.Account
    belongs_to :follows, Sneaky.Auth.Account

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> validate_required([:subject, :follows])
    |> unique_constraint(:follows_subject_follows_constraint, name: :follows_subject_follows)
  end

end
