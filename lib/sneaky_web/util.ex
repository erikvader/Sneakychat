defmodule SneakyWeb.Util do
  import Ecto.Query, only: [from: 2]

  # Returns true if `username` is in our `accounts` table.
  def account_exists?(username) do
    query = from a in Sneaky.Auth.Account,
      where: a.username == ^username
    Sneaky.Repo.exists?(query)
  end

  # returns true if `username` is in our `users` table.
  def user_exists?(username) do
    query = from a in Sneaky.Auth.Account,
      join: u in Sneaky.Auth.User, on: u.account_id == a.id,
      where: a.username == ^username and a.url == "localhost"
    Sneaky.Repo.exists?(query)
  end

  # returns the account schema with `username` and `url`. If this
  # account does not exists, then it is created.
  def get_account(username, url) do
    alias Sneaky.Auth.Account

    %Account{}
    |> Account.changeset(%{username: username, url: url})
    |> Sneaky.Repo.insert(on_conflict: :nothing)
    |> case do
         {:ok, %Account{id: id} = acc} when id != nil -> acc
         _ -> Sneaky.Repo.get_by!(Account, [username: username, url: url])
       end
  end
end
