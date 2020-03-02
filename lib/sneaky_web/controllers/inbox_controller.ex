defmodule SneakyWeb.InboxController do
  use SneakyWeb, :controller
  import SneakyWeb.Lib.Sneak

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
end
