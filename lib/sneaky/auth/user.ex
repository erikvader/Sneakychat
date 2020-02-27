defmodule Sneaky.Auth.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string
    field :role, :integer, default: 0 # 0 = user; 1 = moderator; 2 = admin
    field :is_banned, :boolean, default: false
    belongs_to :account, Sneaky.Auth.Account

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :role, :is_banned])
    |> put_assoc(:account, attrs.account)
    |> validate_required([:email, :password, :account, :role, :is_banned])
    |> unique_constraint(:email)
    |> unique_constraint(:account)
  end

end
