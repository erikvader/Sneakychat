defmodule SneakyWeb.UserChannel do
  use Phoenix.Channel

  def join(
    "user:" <> uid,
    _message,
    %Phoenix.Socket{assigns: %{user_id: user_id}} = socket)
  when user_id == uid do
    {:ok, socket}
  end

  def join(_channel, _message, _socket) do
    {:error, %{reason: "det är olagligt att joina med fel user_id"}}
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

  def handle_in("follow", %{"friend" => url}, socket) do
    # TODO: follow url
    {:noreply, socket}
  end

  def handle_in("unfollow", %{"former_friend" => url}, socket) do
    # TODO: unfollow url
    {:noreply, socket}
  end

  def handle_in("follows", _msg, socket) do
    {:reply, {:ok, %{follows: ["kalle anka", "pelle pellesson"]}}, socket}
  end
end
