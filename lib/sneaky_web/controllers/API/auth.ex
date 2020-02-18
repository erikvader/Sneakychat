defmodule SneakyWeb.API.AuthController do
    @moduledoc """
    Handles authentication requests
    """
    use SneakyWeb, :controller
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
      case Sneaky.Repo.get_by(Sneaky.Auth.User, username: username) do
        nil -> conn |> json(%{"error" => "user not found"})
        user ->
          if user.password == password do
            {:ok, token, _claims} = Sneaky.Guardian.encode_and_sign(user)
            conn |> json(%{"token" => token})
          else
            conn |> json(%{"error" => "incorrect password"})
          end
      end
    end
    def identity_callback(conn, _params), do: conn |> json(%{"error" => "something went wrong"})

    def identity_register(conn, %{"username" => username, "password" => password, "email" => email}) do
      changeset = Sneaky.Auth.User.changeset(%Sneaky.Auth.User{}, %{username: username, password: password, email: email})

      case Sneaky.Repo.insert(changeset) do
        {:ok, _} -> conn |> json(%{"status": "user registered"})
        {:error, changeset} -> conn |> json(%{"error" => "user already exists"}) # TODO: Should actually check changeset errors
      end
    end
    def identity_register(conn, _params), do: conn |> json(%{"error" => "malformed request"})
end
