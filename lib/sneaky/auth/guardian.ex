defmodule Sneaky.Guardian do
  use Guardian, otp_app: :sneaky

  # resource id should be user ID
  def subject_for_token(resource, _claims) do
    {:ok, to_string(resource.id)}
  end
  def subject_for_token(_resource, _claims) do
    {:error, :unknown}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Sneaky.Repo.get(Sneaky.Auth.Account, id)
    resource = Sneaky.Repo.preload(resource, :user)
    {:ok, resource}
  end
  def resource_from_claims(_claims) do
    {:error, :unknown}
  end
end
