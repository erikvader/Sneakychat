defmodule Sneaky.Auth.Sneak do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sneaks" do
    field :url, :string
    belongs_to :sender, Account

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:url])
    |> validate_required([:url, :sender])
    |> unique_constraint(:sneaks_url_sender_constraint, name: :sneaks_url_sender)
  end

end
