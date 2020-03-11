defmodule Sneaky.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "settings" do
    timestamps()
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [])
    |> validate_required([])
  end
end