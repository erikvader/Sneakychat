defmodule SneakyWeb.UserChannel do
  use Phoenix.Channel
  import SneakyWeb.Lib.Sneak

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
  def handle_in("new_sneak", %{"recv_host" => recv_host, "recv_user" => recv_user, "img" => img}, socket) do
    # TODO: allow multiple receivers
    # TODO: respond with which receivers got it

    # "http://localhost/" <> username = receiver
    # SneakyWeb.Endpoint.broadcast_from!(
    #   self(),
    #   "user:#{username}",
    #   "recv_sneak",
    #   %{msg: msg, from: socket.assigns[:username]}
    # )


    my_host = SneakyWeb.Endpoint.url
    filename = :crypto.strong_rand_bytes(128) |> Base.url_encode64 |> binary_part(0, 128)
    img_url = "#{my_host}/sneakies/#{filename}"

    with :ok <- ns_post_to_receiver(recv_host, recv_user, img_url, socket),
         :ok <- ns_upload_image(filename, img, socket),
         {:ok, _} <- add_sneak(
           img_url,
           %{username: socket.assigns.account.username, url: "localhost"},
           %{username: recv_user, url: recv_host}
         ) do
      {:reply, :ok, socket}
    else
      _ -> {:reply, :error, socket}
    end
  end

  defp ns_upload_image(filename, img, _socket) do
    with {:ok, binary_img} <- Base.decode64(img),
         {:ok, _} <- ExAws.S3.put_object("sneakies", filename, binary_img) |> ExAws.request do
      :ok
    else
      err ->
        IO.inspect err
        :error
    end
  end

  defp ns_post_to_receiver(recv_host, recv_user, img_url, socket) do
    # TODO: webfingra this bi$ch
    recv_url = create_user_url(recv_host, recv_user)
    send_url = create_user_url(SneakyWeb.Endpoint.url, socket.assigns.account.username)
    activityp_json = create_new_sneak_json(send_url, recv_url, img_url)

    case HTTPoison.post(recv_url <> "/inbox", activityp_json, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        resp = Jason.decode! body
        if resp["status"] == 0 do
          IO.puts "#{recv_url} all okej!"
          :ok
        else
          IO.puts "status: #{resp["status"]}, msg: #{resp["msg"]}"
          :error
        end
      {:ok, %HTTPoison.Response{status_code: _}} ->
        IO.puts "inte status_code 200"
        :error
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
        :error
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
