defmodule SneakyWeb.UserChannel do
  use Phoenix.Channel
  import SneakyWeb.Lib.Sneak

  def join("user:" <> username, _message, socket) do
    if username == socket.assigns.account.username do
      {:ok, socket}
    else
      {:error, %{reason: "det är olagligt att använda någon annans användarnamn"}}
    end
  end

  def join(_channel, _message, _socket) do
    {:error, %{reason: "det är inte lagligt enligt lag att joina en topic som jag inte tillåter"}}
  end

  # send a sneak to another user
  def handle_in("new_sneak", %{"to" => receivers, "img" => img}, socket) do
    # TODO: check if img is valid
    if receivers_valid? receivers do
      try do
        failed = ns_send_sneaks(receivers, img, socket)
        status = if length(failed) == length(receivers) do :error else :ok end
        {:reply, {status, %{"failed" => failed}}, socket}
      rescue
        e ->
          IO.inspect e
          {:reply, {:error, %{"reason" => "dunno"}}, socket}
      end
    else
      {:reply, {:error, %{"reason" => "bad request"}}, socket}
    end
  end

  def handle_in("new_sneak", _message, socket) do
    {:reply, {:error, %{"reason" => "bad request"}}, socket}
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
    fols = get_follows(socket.assigns.account.id)
    {:reply, {:ok, %{follows: fols}}, socket}
  end

  def handle_in("feed", msg, socket) do
    time =
      with %{"before" => a} <- msg,
           {:ok, t, _} <- DateTime.from_iso8601(a) do
        t
      else
        _ -> nil
      end
    feed = get_feed(socket.assigns.account.id, 10, time)
    {:reply, {:ok, %{feed: feed, valid_before: not is_nil(time), limit: 10}}, socket}
  end

  def handle_in("open", %{"sneak_recv" => sneak_recv_id}, socket) do
    mark_sneak_opened(sneak_recv_id)
    {:reply, :ok, socket}
  end

  # functions for new_sneak ###################################################

  # send sneaks to all receivers
  def ns_send_sneaks(receivers, img, socket) do
    my_host = SneakyWeb.Endpoint.url
    filename = :crypto.strong_rand_bytes(128) |> Base.url_encode64 |> binary_part(0, 128)
    img_url = "#{my_host}/sneakies/#{filename}"

    succ = Enum.map(receivers, fn %{"recv_host" => recv_host, "recv_user" => recv_user} ->
      posted = ns_post_to_receiver(recv_host, recv_user, img_url, socket)
      if :ok == posted do
        {:ok, _} = add_sneak(
          img_url,
          %{username: socket.assigns.account.username, url: "localhost"},
          %{username: recv_user, url: recv_host}
        )
      end
      :ok == posted
    end)

    if Enum.any?(succ) do
      :ok = ns_upload_image(filename, img)
    end

    failed = Enum.zip(succ, receivers)
    |> Enum.filter(fn {s, _} -> not s end)
    |> Enum.map(fn {_, r} -> r end)

    # TODO: send an error message describing why each receiver failed
    failed
  end

  # check if receivers is valid, i.e. it is a non-empty list with
  # correct content and no duplicates
  defp receivers_valid?(receivers) do
    is_list(receivers)
    and not Enum.empty?(receivers)
    and Enum.all?(receivers, fn
      %{"recv_host" => a, "recv_user" => b} when is_binary(a) and is_binary(b) -> true
      _ -> false
    end)
    and (Enum.uniq_by(receivers, fn
      %{"recv_host" => a, "recv_user" => b} -> a <> b
    end) |> length) == length(receivers)
  end

  # upload img to minio
  defp ns_upload_image(filename, img) do
    with {:ok, binary_img} <- Base.decode64(img),
         {:ok, _} <- ExAws.S3.put_object("sneakies", filename, binary_img) |> ExAws.request do
      IO.puts "uploaded img"
      :ok
    else
      err ->
        IO.inspect err
        :error
    end
  end

  # try to send the sneak to a receivers inbox.
  defp ns_post_to_receiver(recv_host, recv_user, img_url, socket) do
    # TODO: get target adress from webfingers
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

  # end of functions for new_sneak ############################################
end
