defmodule SneakyWeb.AuthController do
  import Ecto.Query, only: [from: 2]
  
  use SneakyWeb, :controller
  plug Ueberauth
  alias Ueberauth.Strategy.Helpers

  def request(conn, _params) do
    render(conn, "index.html", callback_url: Helpers.callback_url(conn))
  end
  
  def identity_callback(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
    with %{"username" => username, "password" => password} <- auth.extra.raw_info,
         {:ok, user} <-SneakyWeb.Lib.Auth.authenticate_(username, password)
    do
      conn
      |> put_flash(:info, "Signed in!")
      |> Sneaky.Guardian.Plug.sign_in(user)
      |> configure_session(renew: true)
      |> redirect(to: "/")
    else
      {:error, _} -> 
        conn
        |> put_flash(:error, "Wrong username or password")
        |> redirect(to: "/auth/")
    end
  end

  def identity_callback(conn, _params) do
    conn |> text("Request not decorated with Auth")
  end
end