defmodule SneakyWeb.AuthController do
  import Ecto.Query, only: [from: 2]
  
  use SneakyWeb, :controller

  def request(conn, _params) do
    render(conn, "index.html")
  end
  
  def callback(conn, _params) do
    conn |> text("placeholder")
  end
end