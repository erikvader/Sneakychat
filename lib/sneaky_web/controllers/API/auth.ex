defmodule SneakyWeb.API.AuthController do
    @moduledoc """
    Handles authentication requests
    """
    use SneakyWeb, :controller
    plug Ueberauth

    @doc """
    Requires username and password. Returns JSON containing JWT on successful
    authentication.

    ## Examples
    Successful: %{"jwt": "xxxxx.xxxxx.xxxxx"}
    Error:      %{"error": "reason"}
    """
    # TODO: Rate-Limiting
    def request(conn, params)
    def request(conn, %{"username" => username, "password" => password}) do
        conn |> text(conn)
    end
    def request(conn, _params), do: conn |> json(%{"error" => "malformed request"})

    def identity_callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
        conn |> text("Not implemented")
    end
    def identity_callback(conn, _params), do: conn |> json(%{"error" => "something went wrong"})

    def identity_register(conn, %{"username" => username, "password" => password}) do
        
    end
    def identity_register(conn, _params), do: conn |> json(%{"error" => "malformed request"})
end