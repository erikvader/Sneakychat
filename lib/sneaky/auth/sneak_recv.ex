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
    maybe_put_assoc = fn changeset, key ->
      if Map.has_key?(attrs, key) do
        put_assoc(changeset, key, attrs[key])
      else
        changeset
      end
    end

    user
    |> cast(attrs, [])
    # |> put_assoc(:sneak, attrs.sneak)
    # |> put_assoc(:recv, attrs.recv)
    |> maybe_put_assoc.(:sneak)
    |> maybe_put_assoc.(:recv)
    |> validate_required([:recv, :sneak])
    |> unique_constraint(:sneak_recvs_sneak_id_constraint, name: :sneak_recvs_sneak_id)
  end

end
