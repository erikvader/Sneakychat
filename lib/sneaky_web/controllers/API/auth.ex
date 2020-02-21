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
      query = from a in Sneaky.Auth.Account,
        join: u in Sneaky.Auth.User, on: u.account_id == a.id,
        where: a.username == ^username,
        select: {a, u.password}


      case Sneaky.Repo.one(query) do
        nil -> conn |> json(%{"error" => "user not found"})
        {acc, pass} ->
          if pass == password do
            {:ok, token, _claims} = Sneaky.Guardian.encode_and_sign(acc)
            conn |> json(%{"token" => token})
          else
            conn |> json(%{"error" => "incorrect password"})
          end
      end
    end
    def identity_callback(conn, _params), do: conn |> json(%{"error" => "something went wrong"})

    def identity_register(conn, %{"username" => username, "password" => password, "email" => email}) do
      acc = %Sneaky.Auth.Account{username: username, url: "localhost"}
      usr = %Sneaky.Auth.User{email: email, password: password, account: acc}

      case Sneaky.Repo.insert(usr) do
        {:ok, _} -> conn |> json(%{status: "user registered"})
        {:error, changeset} -> conn |> json(%{"error" => "user already exists"}) # TODO: Should actually check changeset errors
      end
    end
    def identity_register(conn, _params), do: conn |> json(%{"error" => "malformed request"})
end
