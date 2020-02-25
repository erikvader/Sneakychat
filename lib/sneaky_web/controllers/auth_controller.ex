defmodule SneakyWeb.AuthController do
    import Ecto.Query, only: [from: 2]
    plug Ueberauth

    use SneakyWeb, :controller
   
    
    def request(conn, _params) do
        conn |> text("placeholder")
    end

    def callback(conn, _params) do
        conn |> text("placeholder")
    end
end