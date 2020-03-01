defmodule SneakyWeb.UserChannel do
  use Phoenix.Channel

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

  # send a sneak to another user
  def handle_in("new_sneak", %{"receiver" => receiver, "img" => img}, socket) do
    # TODO: lagra att den har skickats någonstans
    # TODO: receiver är en url to en potentiellt annan server, så vi
    # vill egentligen göra en post här till "receiver/inbox" ?

    # "http://localhost/" <> username = receiver
    # SneakyWeb.Endpoint.broadcast_from!(
    #   self(),
    #   "user:#{username}",
    #   "recv_sneak",
    #   %{msg: msg, from: socket.assigns[:username]}
    # )

    my_host = SneakyWeb.Endpoint.url
    filename = :crypto.strong_rand_bytes(128) |> Base.url_encode64 |> binary_part(0, 128)
    with {:ok, binary_img} <- Base.decode64(img),
         {:ok, _} <- ExAws.S3.put_object("sneakies", filename, binary_img) |> ExAws.request do
      img_url = "#{my_host}/sneakies/#{filename}"
      {:reply, :ok, socket}
    else
      _ -> {:reply, :error, socket}
    end
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
