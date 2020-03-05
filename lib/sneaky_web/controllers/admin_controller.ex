defmodule SneakyWeb.AdminController do
  use SneakyWeb, :controller

  def index(conn, _params) do
    conn |> render("index.html")
  end

  def setup(conn, %{"step" => step}) do
    case step do
      "1" ->
        conn
        |> put_flash(:info, "No more steps (admin user created)")
        |> redirect(to: "/admin")
      _ ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> redirect(to: "/admin/setup")
    end
  end

  # TODO: Move out user creation from here.
  def setup(conn = %{method: "GET"}, _params) do
    conn
    |> render("setup.html")
  end
  def setup(conn = %{method: "POST"}, params) do
    with %{"username" => username, 
           "email" => email, 
           "password" => password} <- params,
           {:ok, user} <- SneakyWeb.Lib.Auth.create_user(email, username, password, 2)
    do
      conn
      |> put_flash(:info, "Account created")
      |> Sneaky.Guardian.Plug.sign_in(user, %{"role" => 2}) #! TODO: Use claims from DB
      |> configure_session(renew: true)
      |> redirect(to: "/admin/setup/step/1")
    else
      {:error, _} ->
        # Probably a database error
        # TODO: Improve checking
        conn
        |> put_flash(:error, "Database error")
        |> redirect(to: "/admin/setup")
      _ ->
        conn
        |> put_flash(:error, "Invalid input")
        |> redirect(to: "/admin/setup")
    end
  end
end