defmodule SneakyWeb.API.AuthController do
    @moduledoc """
    Handles authentication requests
    """
    use SneakyWeb, :controller
    import Ecto.Query, only: [from: 2]
    plug Ueberauth

    # Should not be used in the current state.
    def request(conn, params)
    def request(conn, %{"username" => username, "password" => password}) do
        conn |> text("Web-login not enabled")
    end
    def request(conn, _params), do: conn |> json(%{"error" => "malformed request"})

    @doc """
    Requires username and password. Returns JSON containing JWT on successful
    authentication.

    ## Examples
    Successful: %{"jwt": "xxxxx.xxxxx.xxxxx"}
    Error:      %{"error": "reason"}
    """
    # TODO: Implement rate-limiting
    # TODO: Hash passwords
    def identity_callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"username" => username, "password" => password}) do
      case SneakyWeb.Lib.Auth.authenticate(username, password) do
        {:ok, token} -> conn |> json(%{status: 0, token: token})
        {:error, :password} -> conn |> json(%{status: 1, msg: "incorrect password"}) # TODO: Should we really say this?
        {:error, :not_found} -> conn |> json(%{status: 2, msg: "user not found"})
      end
    end
    def identity_callback(conn, _params), do: conn |> json(%{"error" => "something went wrong"})

    def identity_register(conn, %{"username" => username, "password" => password, "email" => email}) do
      alias Sneaky.Auth.Account
      alias Sneaky.Auth.User

      succ = Sneaky.Repo.transaction(fn repo ->
        acc_change = Account.changeset(%Account{}, %{username: username, url: "localhost"})
        with {:ok, acc} <- repo.insert(acc_change),
             usr_change <- User.changeset(%User{}, %{email: email, password: password, account: acc}),
             {:ok, usr} <- repo.insert(usr_change)
        do
          :ok
        else
          {:error, changeset} -> repo.rollback(changeset)
        end
      end)

      case succ do
        {:ok, _} -> conn |> json(%{status: 0, msg: "user registred"})
        {:error, changeset} ->
          case changeset.errors do
            [accounts_username_url_constraint: _] ->
              json(conn, %{status: 2, msg: "username taken"})
            [email: _] ->
              json(conn, %{status: 3, msg: "email in use"})
            _ ->
              IO.inspect(changeset, label: "changeset")
              conn |> json(%{status: 1, msg: "something went wrong"})
          end
      end
    end
    def identity_register(conn, _params), do: conn |> json(%{status: -1, msg: "malformed request"})
end
