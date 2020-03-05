defmodule SneakyWeb.Lib.Auth do
  import Ecto.Query, only: [from: 2]
  
  # TODO: Refactor out the JWT creation
  def authenticate(username, password) do
    query = from a in Sneaky.Auth.Account,
    join: u in Sneaky.Auth.User, on: u.account_id == a.id,
    where: a.username == ^username,
    select: {a, u.password}
    
    case Sneaky.Repo.one(query) do
      nil -> {:error, :not_found}
      {acc, pass} ->
        if pass == password do
          {:ok, token, _claims} = Sneaky.Guardian.encode_and_sign(acc)
          {:ok, token}
        else
          {:error, :password}
        end
      end
    end

  def authenticate_(username, password) do
    query = from a in Sneaky.Auth.Account,
    join: u in Sneaky.Auth.User, on: u.account_id == a.id,
    where: a.username == ^username,
    select: {a, u.password}
    
    case Sneaky.Repo.one(query) do
      nil -> {:error, :not_found}
      {acc, pass} ->
        if pass == password do
          {:ok, acc}
        else
          {:error, :password}
        end
    end
  end

  def create_user(email, username, password, role) do
    alias Sneaky.Auth.Account
    alias Sneaky.Auth.User

    Sneaky.Repo.transaction(fn repo ->
      acc_change = Account.changeset(%Account{}, %{username: username, url: "localhost"})
      with {:ok, acc} <- repo.insert(acc_change),
           usr_change <- User.changeset(%User{}, %{email: email, password: password, account: acc, role: role}),
           {:ok, usr} <- repo.insert(usr_change)
      do
        :ok
      else
        {:error, changeset} -> repo.rollback(changeset)
      end
    end)
  end
end