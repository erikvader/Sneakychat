defmodule SneakyWeb.InboxController do
  use SneakyWeb, :controller
  import SneakyWeb.Util
  import Ecto.Query, only: [from: 2]

  # handle the receiving of a new sneak
  def inbox(conn, %{"type" => "Create",
                    "actor" => actor,
                    "to" => to,
                    "object" => %{"type" => "Link", "href" => href}
                   }) do
    with actor_parse <- URI.parse(actor),
         to_parse <- URI.parse(to),
         "/users/" <> sender <- actor_parse.path,
         "/users/" <> receiver <- to_parse.path,
         true <- user_exists?(receiver),
         {:ok, _} <- add_sneak(
           href,
           %{username: sender, url: actor_parse.host},
           %{username: receiver, url: "localhost"}
         ) do

      # TODO: skicka notifikation här
      json(conn, %{status: 0, msg: "ok"})
    else
      _ -> json(conn, %{status: 1, msg: "any kind of error occured"})
    end
  end

  def inbox(conn, _params) do
    json(conn, %{status: 1, msg: "I do not know that activity pub request"})
  end

  # adds the correct thingies in the database to say that `sender`
  # sent sneak `image_url` to `receiver`.
  # PRE: user_exists?(receiver.username) == true
  defp add_sneak(image_url, sender, receiver) do
    alias Sneaky.Auth.SneakRecv

    receiver_acc = Sneaky.Repo.get_by!(
      Sneaky.Auth.Account,
      [url: receiver.url, username: receiver.username]
    )

    Sneaky.Repo.transaction(fn repo ->
      sender_acc = get_account(sender.username, sender.url)
      sneak = get_sneak(image_url, sender_acc)

      recv_change = SneakRecv.changeset(%SneakRecv{}, %{recv: receiver_acc, sneak: sneak})
      case repo.insert(recv_change) do
        {:ok, _} -> :ok
        {:error, changeset} -> repo.rollback(changeset)
      end
    end)
  end

  # returns the sneak schema with `image_url` and `sender_acc`. If this
  # sneak does not exists, then it is created.
  defp get_sneak(image_url, sender_acc) do
    alias Sneaky.Auth.Sneak

    %Sneak{}
    |> Sneak.changeset(%{url: image_url, sender: sender_acc})
    |> Sneaky.Repo.insert(on_conflict: :nothing)
    |> case do
         {:ok, %Sneak{id: id} = sneak} when id != nil -> sneak
         _ -> Sneaky.Repo.get_by!(Sneak, [url: image_url, sender_id: sender_acc.id])
       end
  end

end
