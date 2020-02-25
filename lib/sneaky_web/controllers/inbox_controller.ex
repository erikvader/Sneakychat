defmodule SneakyWeb.InboxController do
  use SneakyWeb, :controller
  import Ecto.Query, only: [from: 2]

  def inbox(conn, %{"type" => "Create", "actor" => actor, "to" => to, "object" => object}) do
    with actor_parse <- URI.parse(actor),
         to_parse <- URI.parse(to),
         "/users/" <> sender <- actor_parse.path,
         "/users/" <> receiver <- to_parse.path,
         true <- user_exists?(receiver),
         # TODO: this can leave stray accounts, put this in the same
         # transaction as add_sneak?
         {:ok, _} <- assert_exists_account(sender, actor_parse.host),
         {:ok, _} <- add_sneak(
           object["href"],
           %{username: sender, url: actor_parse.host},
           %{username: receiver, url: "localhost"}
         ) do

      json(conn, %{status: 0, msg: "ok"})
    else
      _ -> json(conn, %{status: 1, msg: "invalid actor or to URL"})
    end
  end

  def inbox(conn, _params) do
    # IO.inspect conn
    # IO.inspect params
    json(conn, %{status: 1, msg: "fel"})
  end

  defp add_sneak(image_url, sender, receiver) do
    alias Sneaky.Auth.Sneak
    alias Sneaky.Auth.SneakRecv

    sender_acc = Sneaky.Repo.get_by(
      Sneaky.Auth.Account,
      [url: sender.url, username: sender.username]
    )
    receiver_acc = Sneaky.Repo.get_by(
      Sneaky.Auth.Account,
      [url: receiver.url, username: receiver.username]
    )

    succ = Sneaky.Repo.transaction(fn repo ->
      sneak_change = Sneak.changeset(%Sneak{}, %{url: image_url, sender: sender_acc})

      # TODO: don't fail on sneak already exists, reuse
      with {:ok, sneak} <- repo.insert(sneak_change),
           recv_change <- SneakRecv.changeset(%SneakRecv{}, %{recv: receiver_acc, sneak: sneak}),
           {:ok, _} <- repo.insert(recv_change) do
        :ok
      else
        {:error, changeset} -> repo.rollback(changeset)
      end
    end)

    succ
  end

  defp user_exists?(username) do
    query = from a in Sneaky.Auth.Account,
      join: u in Sneaky.Auth.User, on: u.account_id == a.id,
      where: a.username == ^username and a.url == "localhost"
    Sneaky.Repo.exists?(query)
  end

  defp assert_exists_account(username, url) do
    alias Sneaky.Auth.Account
    query = from a in Account,
      where: a.username == ^username and a.url == ^url
    if not Sneaky.Repo.exists?(query) do
      cha = Account.changeset(%Account{}, %{username: username, url: url})
      Sneaky.Repo.insert(cha)
    else
      {:ok, nil}
    end
  end

end
