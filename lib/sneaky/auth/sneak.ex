defmodule Sneaky.Auth.Sneak do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sneaks" do
    field :url, :string
    belongs_to :sender, Sneaky.Auth.Account

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:url])
    |> put_assoc(:sender, attrs.sender)
    |> validate_required([:url, :sender])
    |> unique_constraint(:sneaks_url_sender_constraint, name: :sneaks_url_sender)
  end

end
