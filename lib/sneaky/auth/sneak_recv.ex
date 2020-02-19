defmodule Sneaky.Auth.SneakRecv do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sneak_recvs" do
    belongs_to :recv, Account
    belongs_to :sneak_id, Sneak

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    # |> cast(attrs, [:])
    |> validate_required([:recv, :sneak_id])
    |> unique_constraint(:sneak_recvs_sneak_id_constraint, name: :sneak_recv_sneak_id)
  end

end
