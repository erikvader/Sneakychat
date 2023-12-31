defmodule Sneaky.Auth.SneakRecv do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sneak_recvs" do
    belongs_to :recv, Sneaky.Auth.Account
    belongs_to :sneak, Sneaky.Auth.Sneak
    field :opened, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:opened])
    |> put_assoc(:sneak, attrs.sneak)
    |> put_assoc(:recv, attrs.recv)
    |> validate_required([:recv, :sneak, :opened])
    |> unique_constraint(:sneak_recvs_sneak_id_constraint, name: :sneak_recvs_sneak_id)
  end

end
