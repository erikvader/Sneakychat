defmodule SneakyWeb.Lib.Sneak do
  import Ecto.Query, only: [from: 2]

  # adds the correct thingies in the database to say that `sender`
  # sent sneak `image_url` to `receiver`.
  def add_sneak(image_url, sender, receiver) do
    alias Sneaky.Auth.SneakRecv

    Sneaky.Repo.transaction(fn repo ->
      receiver_acc = get_account(receiver.username, receiver.url)
      sender_acc = get_account(sender.username, sender.url)
      sneak = get_sneak(image_url, sender_acc)

      recv_change = SneakRecv.changeset(%SneakRecv{}, %{recv: receiver_acc, sneak: sneak})
      case repo.insert(recv_change, on_conflict: :nothing) do
        {:ok, _} -> :ok
        {:error, changeset} -> repo.rollback(changeset)
      end
    end)
  end

  # returns true if `username` is in our `users` table.
  def user_exists?(username) do
    query = from a in Sneaky.Auth.Account,
      join: u in Sneaky.Auth.User, on: u.account_id == a.id,
      where: a.username == ^username and a.url == "localhost"
    Sneaky.Repo.exists?(query)
  end

  # Returns true if `username` is in our `accounts` table.
  def account_exists?(username) do
    query = from a in Sneaky.Auth.Account,
      where: a.username == ^username
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

  # returns the sneak schema with `image_url` and `sender_acc`. If this
  # sneak does not exists, then it is created.
  def get_sneak(image_url, sender_acc) do
    alias Sneaky.Auth.Sneak

    %Sneak{}
    |> Sneak.changeset(%{url: image_url, sender: sender_acc})
    |> Sneaky.Repo.insert(on_conflict: :nothing)
    |> case do
         {:ok, %Sneak{id: id} = sneak} when id != nil -> sneak
         _ -> Sneaky.Repo.get_by!(Sneak, [url: image_url, sender_id: sender_acc.id])
       end
  end

  def mark_sneak_opened(sneak_recv_id) do
    alias Sneaky.Auth.SneakRecv

    with sr when not is_nil(sr) <- Sneaky.Repo.get(SneakRecv, sneak_recv_id),
         new_sr <- Ecto.Changeset.change(sr, opened: true),
         {:ok, _} <- Sneaky.Repo.update(new_sr) do
      :ok
    else
      err ->
        IO.inspect(err, label: "sneak_opened_error")
        :error
    end
  end

  def create_user_url(host, username) do
    if not String.starts_with?(host, "http://") do
      create_user_url("http://" <> host, username)
    else
      host <> "/users/" <> username
    end
  end

  def create_new_sneak_json(send_url, recv_url, img_url) do
    Jason.encode! %{
      "type" => "Create",
      "actor" => send_url,
      "to" => recv_url,
      "object" => %{
        "type" => "Link",
        "href" => img_url,
        "mediaType" => "image/png"
      }
    }
  end

  def get_follows(uid) do
    q = from f in Sneaky.Auth.Follow,
      join: a in Sneaky.Auth.Account, on: f.follows_id == a.id,
      where: f.subject_id == ^uid,
      select: %{"username" => a.username, "host" => a.url}

    Sneaky.Repo.all(q)
  end

  def get_feed(uid, limit, before) do
    # NOTE: oerhört fult att kopiera så här, men jag pallade inte
    # lista ut hur man gjorde det snyggt... (eller det gick inge bra i
    # alla fall) Fixa gärna!
    if not is_nil before do
      from a in Sneaky.Auth.Account,
        join: s in Sneaky.Auth.Sneak, on: s.sender_id == a.id,
        join: r in Sneaky.Auth.SneakRecv, on: r.sneak_id == s.id and r.recv_id == ^uid,
        limit: ^limit,
        where: s.inserted_at < ^before and not r.opened,
        order_by: [desc: s.inserted_at],
        select: %{"username" => a.username, "url" => s.url, "send_date" => s.inserted_at, "sneak_recv" => r.id}
    else
      from a in Sneaky.Auth.Account,
        join: s in Sneaky.Auth.Sneak, on: s.sender_id == a.id,
        join: r in Sneaky.Auth.SneakRecv, on: r.sneak_id == s.id and r.recv_id == ^uid,
        limit: ^limit,
        where: not r.opened,
        order_by: [desc: s.inserted_at],
        select: %{"username" => a.username, "url" => s.url, "send_date" => s.inserted_at, "sneak_recv" => r.id}
    end
    |> Sneaky.Repo.all
  end
end
