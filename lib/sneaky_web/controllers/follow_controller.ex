defmodule SneakyWeb.FollowController do
  use SneakyWeb, :controller
  import SneakyWeb.Util

  # Handle following requests
  def follow(conn, %{"type" => "Follow",
                     "actor" => actor,
                     "object" => object}) do
    with actor_uri <- URI.parse(actor),
         object_uri <- URI.parse(object),
         "/users/" <> follower <- actor_uri.path,
         "/users/" <> followee <- object_uri.path do
      if user_exists?(follower) do
        case add_follower(
              %{username: follower, url: actor_uri.host},
              %{username: followee, url: "localhost"}
            ) do
          :ok -> json(conn, %{status: 0, msg: "ok"})
          :error -> json(conn, %{status: 1, msg: "already following"})
        end
      else
        json(conn, %{status: 2, msg: "no such user"})
      end
    end
  end

  def follow(conn, _) do
    json(conn, %{status: 1, msg: "you did a bad"})
  end

  # Adds `follower` as a follower of `followee`
  # Returns :error if `follower` already follows `followee`, else :ok
  # PRE: user_exists?(follower) == true
  defp add_follower(follower, followee) do
    alias Sneaky.Auth.Follow

    wer_acc = Sneaky.Repo.get_by!(Sneaky.Auth.Account, [username: follower.username, url: follower.url])
    wee_acc = get_account(followee.username, followee.url)

    %Follow{}
    |> Follow.changeset(%{subject: wee_acc, follows: wer_acc})
    |> Sneaky.Repo.insert
    |> case do
         {:ok, _} -> :ok
         {:error, _} -> :error
       end
  end
end
