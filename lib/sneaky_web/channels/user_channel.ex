defmodule SneakyWeb.UserChannel do
  use Phoenix.Channel
  import SneakyWeb.Util

  def join("user:" <> uid, _message, socket) do
    if uid == socket.assigns.user_id do
      {:ok, socket}
    else
      {:error, %{reason: "det är olagligt att joina med fel user_id, försöker du att impersonata någon??"}}
    end
  end

  def join(_channel, _message, _socket) do
    {:error, %{reason: "det är inte lagligt enligt lag att joina en topic som jag inte tillåter"}}
  end

  # send a sneak to another connected user
  def handle_in("new_sneak", %{"receiver" => receiver, "msg" => msg}, socket) do
    # TODO: faktiskt ladda upp bild
    # TODO: lagra att den har skickats någonstans
    # TODO: receiver är en url to en potentiellt annan server, så vi
    # vill egentligen göra en post här till "receiver/inbox" ?

    # "http://localhost/" <> username = receiver
    # SneakyWeb.Endpoint.broadcast_from!(
    #   self(),
    #   "user:#{username}",
    #   "recv_sneak",
    #   %{msg: msg, from: socket.assigns[:username]} # TODO: stoppa in vår egna domän?
    # )
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"receiver" => receiver, "msg" => msg}, socket) do
    {:noreply, socket}
  end

  def handle_in("follow", %{"friend" => friend}, socket) do
    alias Sneaky.Auth.Account
    alias Sneaky.Auth.Follow

    user_acc = socket.assigns.account

    with uri <- URI.parse(friend),
         "/users/" <> friend <- uri.path do
      friend_acc = get_account(friend, uri.host)

      %Follow{}
      |> Follow.changeset(%{subject: user_acc, follows: friend_acc})
      |> Sneaky.Repo.insert
      |> case do
           {:ok, _} -> {:reply, :ok, socket}
           {:error, _} -> {:reply, {:error, %{reason: "already following"}}, socket}
         end
    end
  end

  def handle_in("unfollow", %{"not_friend" => not_friend}, socket) do
    alias Sneaky.Auth.Account
    alias Sneaky.Auth.Follow

    user_acc = socket.assigns.account

    with uri <- URI.parse(not_friend),
         "/users/" <> not_friend <- uri.path do
      case Sneaky.Repo.get_by(Account, [username: not_friend, url: uri.host]) do
        nil -> {:reply, {:error, %{reason: "no such account"}}, socket}
        not_friend_acc ->
          case Sneaky.Repo.get_by(Follow, [subject_id: user_acc.id, follows_id: not_friend_acc.id]) do
            nil -> {:reply, {:error, %{reason: "not following"}}, socket}
            follow ->
              Sneaky.Repo.delete!(follow)
              {:reply, :ok, socket}
          end
      end
    end
  end

  def handle_in("follows", _msg, socket) do
    {:reply, {:ok, %{follows: ["kalle anka", "pelle pellesson"]}}, socket}
  end
end
